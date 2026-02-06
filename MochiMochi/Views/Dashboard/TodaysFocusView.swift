import SwiftUI

struct TodaysFocusView: View {
    @EnvironmentObject var appState: AppState
    @State private var hoveredTaskId: UUID?
    @State private var hoveredAddIndex: Int?
    @State private var showAddForm = false
    @State private var editingTask: MochiTask?

    private var activeTasks: [MochiTask] {
        appState.tasks
            .filter { !$0.isCompleted }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                timelineWrapper
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAddForm) {
            TaskFormSheet(mode: .add) { task in
                appState.addTask(task)
            }
        }
        .sheet(item: $editingTask) { task in
            TaskFormSheet(mode: .edit(task)) { updated in
                appState.updateTask(updated)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Focus du jour")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MochiTheme.textLight)

            Spacer()

            HStack(spacing: 8) {
                headerButton(icon: "minus") {}
                headerButton(icon: "plus") {
                    showAddForm = true
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private func headerButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(.white)
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timeline

    private var timelineWrapper: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 2)
                .padding(.leading, 38)

            VStack(alignment: .leading, spacing: 0) {
                if activeTasks.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(activeTasks.enumerated()), id: \.element.id) { _, task in
                        taskTimelineItem(task: task)
                    }

                    addSlotButton
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sun.max")
                .font(.system(size: 32))
                .foregroundStyle(MochiTheme.pastelYellow)
            Text("Aucune tâche pour aujourd'hui")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
            Button {
                showAddForm = true
            } label: {
                Text("Ajouter une tâche")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MochiTheme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(MochiTheme.primary, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Task Timeline Item

    private func taskTimelineItem(task: MochiTask) -> some View {
        let isHovered = hoveredTaskId == task.id
        return HStack(alignment: .top, spacing: 0) {
            Text(timeString(for: task))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                .frame(width: 40, alignment: .trailing)
                .lineLimit(1)
                .fixedSize()
                .padding(.top, 16)

            ZStack {
                Circle()
                    .fill(dotColor(for: task.priority))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
                    .shadow(color: dotColor(for: task.priority).opacity(0.3), radius: 3, y: 1)
                    .scaleEffect(isHovered ? 1.25 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
            .frame(width: 14)
            .padding(.top, 18)
            .padding(.horizontal, 4)
            .zIndex(10)
            .onHover { hovering in
                hoveredTaskId = hovering ? task.id : nil
            }

            taskCard(for: task)
                .padding(.leading, 6)
                .padding(.trailing, 4)
        }
        .padding(.bottom, 4)
    }

    private func timeString(for task: MochiTask) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: task.createdAt)
    }

    private func dotColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high: return MochiTheme.primary
        case .normal: return Color(hex: "4ADE80")
        case .low: return Color(hex: "F4A261")
        }
    }

    private func taskCard(for task: MochiTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(categoryLabel(for: task.priority))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(cardTextColor(for: task.priority))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white.opacity(0.6))
                    )

                Spacer()

                Button {
                    editingTask = task
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundStyle(cardTextColor(for: task.priority).opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            Text(task.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(MochiTheme.textLight)
                .lineLimit(1)

            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                    .lineLimit(2)
            }

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text(estimatedDuration(for: task.priority))
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(MochiTheme.textLight.opacity(0.4))
            .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadius)
                .fill(cardBackgroundColor(for: task.priority))
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadius)
                        .stroke(cardBorderColor(for: task.priority), lineWidth: 1)
                )
        )
    }

    private func cardBackgroundColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high: return MochiTheme.pastelBlue.opacity(0.2)
        case .normal: return MochiTheme.pastelGreen.opacity(0.2)
        case .low: return MochiTheme.pastelYellow.opacity(0.2)
        }
    }

    private func cardBorderColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high: return MochiTheme.pastelBlue.opacity(0.3)
        case .normal: return MochiTheme.pastelGreen.opacity(0.3)
        case .low: return MochiTheme.pastelYellow.opacity(0.3)
        }
    }

    private func cardTextColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high: return Color(hex: "2563EB")
        case .normal: return Color(hex: "15803D")
        case .low: return Color(hex: "EA580C")
        }
    }

    private func categoryLabel(for priority: TaskPriority) -> String {
        switch priority {
        case .high: return "Deep Work"
        case .normal: return "Meeting"
        case .low: return "Planning"
        }
    }

    private func estimatedDuration(for priority: TaskPriority) -> String {
        switch priority {
        case .high: return "1h 30m"
        case .normal: return "45m"
        case .low: return "15m"
        }
    }

    // MARK: - Add Slot

    private var addSlotButton: some View {
        let isHovered = hoveredAddIndex == 0

        return HStack(alignment: .center, spacing: 0) {
            Color.clear
                .frame(width: 40)

            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
            }
            .frame(width: 14)
            .padding(.horizontal, 4)
            .zIndex(10)

            Button {
                showAddForm = true
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(
                            isHovered ? MochiTheme.primary : MochiTheme.textLight.opacity(0.3)
                        )
                    Spacer()
                }
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadius)
                        .stroke(
                            isHovered ? MochiTheme.primary : Color.gray.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: MochiTheme.cornerRadius)
                                .fill(isHovered ? MochiTheme.primary.opacity(0.05) : .clear)
                        )
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                hoveredAddIndex = hovering ? 0 : nil
            }
            .padding(.leading, 6)
            .padding(.trailing, 4)
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Task Form Sheet

struct TaskFormSheet: View {
    enum Mode {
        case add
        case edit(MochiTask)
    }

    let mode: Mode
    let onSave: (MochiTask) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var priority: TaskPriority = .normal
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date().addingTimeInterval(3600)

    private var editingTask: MochiTask? {
        if case .edit(let task) = mode { return task }
        return nil
    }

    private var isEditing: Bool { editingTask != nil }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Divider().opacity(0.3)
            formContent
            Divider().opacity(0.3)
            sheetFooter
        }
        .frame(width: 380, height: hasDeadline ? 380 : 340)
        .background(Color.white)
        .onAppear {
            if let task = editingTask {
                title = task.title
                description = task.description ?? ""
                priority = task.priority
                hasDeadline = task.deadline != nil
                deadline = task.deadline ?? Date().addingTimeInterval(3600)
            }
        }
    }

    private var sheetHeader: some View {
        HStack {
            Text(isEditing ? "Modifier la tâche" : "Nouvelle tâche")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MochiTheme.textLight)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.gray.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Titre")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("Ex: Revoir la maquette", text: $title)
                        .font(.system(size: 14))
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(MochiTheme.backgroundLight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                )
                        )
                }

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description (optionnel)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("Ajouter des détails...", text: $description, axis: .vertical)
                        .font(.system(size: 13))
                        .lineLimit(2...4)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(MochiTheme.backgroundLight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                )
                        )
                }

                // Priority
                VStack(alignment: .leading, spacing: 6) {
                    Text("Priorité")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            priorityButton(p)
                        }
                    }
                }

                // Deadline toggle + picker
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: $hasDeadline) {
                        Text("Deadline")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .toggleStyle(.switch)
                    .tint(MochiTheme.primary)

                    if hasDeadline {
                        DatePicker("", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func priorityButton(_ p: TaskPriority) -> some View {
        let isSelected = priority == p
        let color = priorityButtonColor(p)
        return Button {
            priority = p
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(p.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? color.opacity(0.15) : Color.gray.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? color : MochiTheme.textLight.opacity(0.5))
        }
        .buttonStyle(.plain)
    }

    private func priorityButtonColor(_ p: TaskPriority) -> Color {
        switch p {
        case .high: return Color(hex: "EF4444")
        case .normal: return MochiTheme.secondary
        case .low: return Color(hex: "F4A261")
        }
    }

    private var sheetFooter: some View {
        HStack {
            if isEditing {
                Button {
                    if let task = editingTask {
                        // Need to find AppState to delete - use onSave with empty title as signal
                        var deleted = task
                        deleted.title = ""
                        onSave(deleted)
                    }
                    dismiss()
                } label: {
                    Text("Supprimer")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Annuler")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Button {
                saveTask()
            } label: {
                Text(isEditing ? "Enregistrer" : "Ajouter")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            title.trimmingCharacters(in: .whitespaces).isEmpty
                                ? MochiTheme.primary.opacity(0.4)
                                : MochiTheme.primary
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        if let existing = editingTask {
            var updated = existing
            updated.title = trimmedTitle
            updated.description = description.isEmpty ? nil : description
            updated.priority = priority
            updated.deadline = hasDeadline ? deadline : nil
            onSave(updated)
        } else {
            let task = MochiTask(
                title: trimmedTitle,
                description: description.isEmpty ? nil : description,
                priority: priority,
                deadline: hasDeadline ? deadline : nil
            )
            onSave(task)
        }
        dismiss()
    }
}

#Preview {
    TodaysFocusView()
        .environmentObject(AppState())
        .frame(width: 320, height: 600)
        .background(MochiTheme.backgroundLight)
}

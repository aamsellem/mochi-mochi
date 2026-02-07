import SwiftUI
import AppKit

// MARK: - Task Filter

enum TaskFilter: String, CaseIterable {
    case all = "Toutes"
    case inProgress = "En cours"
    case tracked = "Suivies"
}

struct TodaysFocusView: View {
    @EnvironmentObject var appState: AppState
    @State private var newTaskTitle: String = ""
    @State private var editingTask: MochiTask?
    @State private var selectedFilter: TaskFilter = .all
    @State private var hoveredTaskId: UUID?
    @FocusState private var isQuickAddFocused: Bool

    private var filteredTasks: [MochiTask] {
        let active = appState.tasks.filter { !$0.isCompleted }
        switch selectedFilter {
        case .all:
            return active.sorted { $0.createdAt > $1.createdAt }
        case .inProgress:
            return active.filter { $0.isInProgress }.sorted { $0.createdAt > $1.createdAt }
        case .tracked:
            return active.filter { $0.isTracked }.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private var activeCount: Int {
        appState.tasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 12)

            quickAddField
                .padding(.bottom, 12)

            filterBar
                .padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                if filteredTasks.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredTasks) { task in
                            taskRow(task)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $editingTask) { task in
            TaskFormSheet(mode: .edit(task)) { updated in
                if updated.title.isEmpty {
                    appState.deleteTask(task)
                } else {
                    appState.updateTask(updated)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("Mes taches")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MochiTheme.textLight)

            Text("\(activeCount)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MochiTheme.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(MochiTheme.primary.opacity(0.15)))

            Spacer()
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Quick Add

    private var quickAddField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(MochiTheme.primary.opacity(0.6))

            TextField("Ajouter une tache...", text: $newTaskTitle)
                .font(.system(size: 14))
                .foregroundStyle(MochiTheme.textLight)
                .textFieldStyle(.plain)
                .focused($isQuickAddFocused)
                .onSubmit {
                    addQuickTask()
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            isQuickAddFocused ? MochiTheme.primary.opacity(0.4) : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
        .padding(.horizontal, 8)
    }

    private func addQuickTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let task = MochiTask(title: trimmed)
        appState.addTask(task)
        newTaskTitle = ""
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 6) {
            ForEach(TaskFilter.allCases, id: \.self) { filter in
                filterPill(filter)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
    }

    private func filterPill(_ filter: TaskFilter) -> some View {
        let isSelected = selectedFilter == filter
        let count: Int = {
            let active = appState.tasks.filter { !$0.isCompleted }
            switch filter {
            case .all: return active.count
            case .inProgress: return active.filter { $0.isInProgress }.count
            case .tracked: return active.filter { $0.isTracked }.count
            }
        }()

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 4) {
                Text(filter.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isSelected ? .white : MochiTheme.textLight.opacity(0.4))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(isSelected ? .white.opacity(0.3) : Color.gray.opacity(0.12))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? .white : MochiTheme.textLight.opacity(0.6))
            .background(
                Capsule().fill(isSelected ? MochiTheme.primary : Color.gray.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Task Row

    private func taskRow(_ task: MochiTask) -> some View {
        let isHovered = hoveredTaskId == task.id

        return HStack(spacing: 10) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    appState.completeTask(task)
                }
            } label: {
                Circle()
                    .stroke(MochiTheme.textLight.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(MochiTheme.primary)
                            .opacity(isHovered ? 0.5 : 0)
                    )
            }
            .buttonStyle(.plain)

            // Title (tap to edit)
            Text(task.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MochiTheme.textLight)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    editingTask = task
                }

            // In progress toggle
            Button {
                appState.toggleInProgress(task)
            } label: {
                Image(systemName: task.isInProgress ? "play.circle.fill" : "play.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(task.isInProgress ? MochiTheme.secondary : MochiTheme.textLight.opacity(0.25))
            }
            .buttonStyle(.plain)
            .help("En cours")

            // Tracked toggle (bell)
            Button {
                appState.toggleTracked(task)
            } label: {
                Image(systemName: task.isTracked ? "bell.fill" : "bell")
                    .font(.system(size: 14))
                    .foregroundStyle(task.isTracked ? MochiTheme.primary : MochiTheme.textLight.opacity(0.25))
            }
            .buttonStyle(.plain)
            .help("Suivi (relances notif)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color.gray.opacity(0.04) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .onHover { hovering in
            hoveredTaskId = hovering ? task.id : nil
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedFilter == .all ? "sun.max" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 32))
                .foregroundStyle(MochiTheme.pastelYellow)

            Text(emptyMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyMessage: String {
        switch selectedFilter {
        case .all: return "Aucune tache en cours\nAjoute-en une ci-dessus !"
        case .inProgress: return "Aucune tache en cours"
        case .tracked: return "Aucune tache suivie"
        }
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
    @State private var showDeadlinePicker: Bool = false

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
        .frame(width: 420, height: 530)
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
            Text(isEditing ? "Modifier la tache" : "Nouvelle tache")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MochiTheme.textLight)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.gray.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text("Titre")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                MochiTextField("Ex: Revoir la maquette", text: $title, fontSize: 14)
                    .frame(height: 20)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
            }

            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text("Description (optionnel)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                MochiTextField("Ajouter des details...", text: $description, fontSize: 13)
                    .frame(height: 20)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
            }

            // Priority
            VStack(alignment: .leading, spacing: 6) {
                Text("Priorite")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                HStack(spacing: 8) {
                    ForEach(TaskPriority.allCases, id: \.self) { p in
                        priorityButton(p)
                    }
                }
            }

            // Deadline
            VStack(alignment: .leading, spacing: 6) {
                Text("Deadline")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))

                HStack(spacing: 10) {
                    // Calendar button
                    Button {
                        if hasDeadline {
                            hasDeadline = false
                        } else {
                            hasDeadline = true
                            showDeadlinePicker = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: hasDeadline ? "calendar.badge.checkmark" : "calendar.badge.plus")
                                .font(.system(size: 14))

                            if hasDeadline {
                                Text(deadline, format: .dateTime.day().month(.wide).year())
                                    .font(.system(size: 12, weight: .medium))
                            } else {
                                Text("Ajouter une date")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                        .foregroundStyle(hasDeadline ? MochiTheme.primary : MochiTheme.textLight.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(hasDeadline ? MochiTheme.primary.opacity(0.08) : Color.gray.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(hasDeadline ? MochiTheme.primary.opacity(0.25) : Color.gray.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showDeadlinePicker) {
                        VStack(spacing: 12) {
                            DatePicker(
                                "Deadline",
                                selection: $deadline,
                                in: Date()...,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .tint(MochiTheme.primary)

                            HStack {
                                Button("Retirer") {
                                    hasDeadline = false
                                    showDeadlinePicker = false
                                }
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.7))

                                Spacer()

                                Button("OK") {
                                    showDeadlinePicker = false
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MochiTheme.primary)
                            }
                        }
                        .padding(16)
                        .frame(width: 280)
                    }

                    // Edit date if already set
                    if hasDeadline {
                        Button {
                            showDeadlinePicker = true
                        } label: {
                            Text("Modifier")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(MochiTheme.primary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxHeight: .infinity)
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
        case .high: return MochiTheme.errorRed
        case .normal: return MochiTheme.secondary
        case .low: return MochiTheme.priorityLow
        }
    }

    private var sheetFooter: some View {
        HStack {
            if isEditing {
                Button {
                    if let task = editingTask {
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

// MARK: - MochiTextField (NSTextView direct)

struct MochiTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var fontSize: CGFloat

    init(_ placeholder: String = "", text: Binding<String>, fontSize: CGFloat = 14) {
        self.placeholder = placeholder
        self._text = text
        self.fontSize = fontSize
    }

    func makeNSView(context: Context) -> NSView {
        let container = NSView()

        let textView = MochiNSTextView()
        textView.string = text
        textView.font = .systemFont(ofSize: fontSize)
        textView.textColor = NSColor(MochiTheme.textLight)
        textView.drawsBackground = false
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(red: 1.0, green: 0.62, blue: 0.67, alpha: 0.4)
        ]
        textView.insertionPointColor = NSColor(MochiTheme.primary)
        textView.delegate = context.coordinator
        textView.translatesAutoresizingMaskIntoConstraints = false

        // Placeholder label
        let placeholderLabel = NSTextField(labelWithString: placeholder)
        placeholderLabel.font = .systemFont(ofSize: fontSize)
        placeholderLabel.textColor = NSColor(MochiTheme.textPlaceholder)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.isHidden = !text.isEmpty
        placeholderLabel.tag = 999

        container.addSubview(textView)
        container.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 2),
            placeholderLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let textView = nsView.subviews.compactMap({ $0 as? NSTextView }).first else { return }
        if textView.string != text {
            textView.string = text
        }
        if let label = nsView.viewWithTag(999) as? NSTextField {
            label.isHidden = !text.isEmpty
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MochiTextField
        init(_ parent: MochiTextField) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
            // Update placeholder visibility
            if let container = tv.superview,
               let label = container.viewWithTag(999) as? NSTextField {
                label.isHidden = !tv.string.isEmpty
            }
        }
    }
}

// Single-line NSTextView that blocks Return key
class MochiNSTextView: NSTextView {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 { return } // Block Return
        super.keyDown(with: event)
    }
}

#Preview {
    TodaysFocusView()
        .environmentObject(AppState())
        .frame(width: 320, height: 600)
        .background(MochiTheme.backgroundLight)
}

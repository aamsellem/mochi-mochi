import SwiftUI

struct TasksTrackingView: View {
    @EnvironmentObject var appState: AppState
    @State private var newTaskTitle = ""
    @State private var newTaskDeadline: Date? = nil
    @State private var showDatePicker = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedSort: TaskSort = .priority
    @State private var showSortMenu = false
    @State private var editingTask: MochiTask?

    enum TaskFilter: String, CaseIterable {
        case all = "Toutes"
        case active = "En cours"
        case completed = "Terminées"
        case overdue = "En retard"
    }

    enum TaskSort: String, CaseIterable {
        case priority = "Priorité"
        case deadline = "Deadline"
        case creation = "Création"
        case alphabetical = "A → Z"
    }

    var body: some View {
        HStack(spacing: 16) {
            mainContent
            sidebar
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)
            taskList
            addTaskBar
        }
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous))
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

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Suivi des Tâches")
                        .font(.title2.bold())
                        .foregroundStyle(MochiTheme.textLight)
                    Text("\(activeTasks.count) en cours · \(completedTasks.count) terminées")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("Trier par")
                        .font(.system(size: 12))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.5))

                    Menu {
                        ForEach(TaskSort.allCases, id: \.self) { sort in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedSort = sort }
                            } label: {
                                HStack {
                                    Text(sort.rawValue)
                                    if selectedSort == sort {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 11, weight: .semibold))
                            Text(selectedSort.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(MochiTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(MochiTheme.primary.opacity(0.1))
                                .overlay(
                                    Capsule().stroke(MochiTheme.primary.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }

            HStack(spacing: 6) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    filterPill(filter)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func filterPill(_ filter: TaskFilter) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = filter }
        } label: {
            HStack(spacing: 5) {
                Text(filter.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                if filter != .all {
                    Text("\(countFor(filter))")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(selectedFilter == filter ? Color.white.opacity(0.3) : MochiTheme.textLight.opacity(0.08))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(selectedFilter == filter ? MochiTheme.primary : Color.gray.opacity(0.08))
                    .overlay(
                        Capsule().stroke(
                            selectedFilter == filter ? Color.clear : Color.gray.opacity(0.15),
                            lineWidth: 1
                        )
                    )
            )
            .foregroundStyle(selectedFilter == filter ? .white : MochiTheme.textLight.opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    private func countFor(_ filter: TaskFilter) -> Int {
        switch filter {
        case .all: return appState.tasks.count
        case .active: return activeTasks.count
        case .completed: return completedTasks.count
        case .overdue: return overdueTasks.count
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if filteredTasks.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredTasks) { task in
                        taskRow(task)
                    }
                }
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36))
                .foregroundStyle(MochiTheme.pastelGreen)
            Text("Aucune tâche dans cette catégorie")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private func taskRow(_ task: MochiTask) -> some View {
        HStack(spacing: 12) {
            Button {
                if !task.isCompleted {
                    withAnimation(.spring(response: 0.3)) {
                        appState.completeTask(task)
                    }
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(task.isCompleted ? MochiTheme.pastelGreen : Color.gray.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(task.isCompleted)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(task.isCompleted ? MochiTheme.textLight.opacity(0.4) : MochiTheme.textLight)
                    .strikethrough(task.isCompleted, color: MochiTheme.textLight.opacity(0.3))

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                        .lineLimit(1)
                }
            }

            Spacer()

            priorityDot(task.priority)

            if let deadline = task.deadline {
                deadlineTag(deadline, isOverdue: task.isOverdue)
            }

            Text(xpReward(task.priority))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MochiTheme.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(MochiTheme.primary.opacity(0.1))
                )

            if !task.isCompleted {
                Button {
                    editingTask = task
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(task.isOverdue ? Color.red.opacity(0.04) : Color.gray.opacity(0.03))
        )
        .onTapGesture(count: 2) {
            guard !task.isCompleted else { return }
            editingTask = task
        }
    }

    private func priorityDot(_ priority: TaskPriority) -> some View {
        Circle()
            .fill(priorityColor(priority))
            .frame(width: 8, height: 8)
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return MochiTheme.errorRed
        case .normal: return MochiTheme.priorityNormal
        case .low: return MochiTheme.priorityLow
        }
    }

    private func deadlineTag(_ date: Date, isOverdue: Bool) -> some View {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .abbreviated
        return Text(formatter.localizedString(for: date, relativeTo: Date()))
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(isOverdue ? .red : .secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(isOverdue ? Color.red.opacity(0.08) : Color.gray.opacity(0.06))
            )
    }

    private func xpReward(_ priority: TaskPriority) -> String {
        switch priority {
        case .high: return "+50 XP"
        case .normal: return "+25 XP"
        case .low: return "+10 XP"
        }
    }

    // MARK: - Add Task Bar

    private var addTaskBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle")
                .font(.system(size: 18))
                .foregroundStyle(MochiTheme.primary.opacity(0.6))

            ZStack(alignment: .leading) {
                if newTaskTitle.isEmpty {
                    Text("Ajouter une tâche...")
                        .font(.system(size: 14))
                        .foregroundStyle(MochiTheme.textPlaceholder)
                        .allowsHitTesting(false)
                }
                TextField("", text: $newTaskTitle)
                    .font(.system(size: 14))
                    .foregroundStyle(MochiTheme.textLight)
                    .textFieldStyle(.plain)
                    .tint(MochiTheme.primary)
                    .onSubmit { addTask() }
            }

            // Date picker button
            Button {
                showDatePicker.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    if let deadline = newTaskDeadline {
                        Text(deadline, style: .date)
                            .font(.system(size: 11))
                    }
                }
                .foregroundStyle(newTaskDeadline != nil ? MochiTheme.primary : Color.gray.opacity(0.6))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDatePicker) {
                VStack(spacing: 12) {
                    DatePicker(
                        "Deadline",
                        selection: Binding(
                            get: { newTaskDeadline ?? Calendar.current.date(byAdding: .day, value: 1, to: Date())! },
                            set: { newTaskDeadline = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(MochiTheme.primary)

                    HStack {
                        if newTaskDeadline != nil {
                            Button("Retirer") {
                                newTaskDeadline = nil
                                showDatePicker = false
                            }
                            .font(.system(size: 12))
                            .foregroundStyle(.red.opacity(0.7))
                        }
                        Spacer()
                        Button("OK") {
                            showDatePicker = false
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MochiTheme.primary)
                    }
                }
                .padding(16)
                .frame(width: 280)
            }

            Button(action: addTask) {
                Text("Ajouter")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(
                            newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                ? MochiTheme.primary.opacity(0.4)
                                : MochiTheme.primary
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadius, style: .continuous)
                .fill(MochiTheme.backgroundLight)
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadius, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(14)
    }

    // MARK: - Sidebar Stats

    private var sidebar: some View {
        VStack(spacing: 16) {
            progressCard
            statsCards
            recentCompletions
            Spacer()
        }
        .frame(width: 240)
    }

    private var progressCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: completionRate)
                    .stroke(MochiTheme.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: completionRate)
                VStack(spacing: 2) {
                    Text("\(Int(completionRate * 100))%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(MochiTheme.textLight)
                    Text("complété")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            Text("Progression du jour")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white, MochiTheme.accent.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }

    private var statsCards: some View {
        VStack(spacing: 10) {
            miniStatRow(icon: "flame.fill", color: .orange, label: "Streak", value: "\(appState.gamification.streakDays) jours")
            miniStatRow(emoji: "🍙", color: .orange, label: "Grains de riz", value: "\(appState.gamification.riceGrains)")
            miniStatRow(icon: "star.fill", color: MochiTheme.primary, label: "Niveau", value: "\(appState.gamification.level)")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }

    private func miniStatRow(icon: String? = nil, emoji: String? = nil, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Group {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 14))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(color)
                }
            }
            .frame(width: 28, height: 28)
            .background(Circle().fill(color.opacity(0.12)))

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(MochiTheme.textLight)
        }
    }

    private var recentCompletions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Récemment terminées")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight)

            if completedTodayTasks.isEmpty {
                Text("Aucune tâche terminée aujourd'hui")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(completedTodayTasks.prefix(5)) { task in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(MochiTheme.pastelGreen)
                        Text(task.title)
                            .font(.system(size: 11))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                .fill(MochiTheme.pastelGreen.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                        .stroke(MochiTheme.pastelGreen.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Data

    private var filteredTasks: [MochiTask] {
        let base: [MochiTask]
        switch selectedFilter {
        case .all:
            // Actives en haut, complétées en bas
            let active = sortTasks(appState.tasks.filter { !$0.isCompleted })
            let completed = appState.tasks.filter { $0.isCompleted }
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            return active + completed
        case .active:
            base = activeTasks
        case .completed:
            return completedTasks.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        case .overdue:
            base = overdueTasks
        }
        return sortTasks(base)
    }

    private func sortTasks(_ tasks: [MochiTask]) -> [MochiTask] {
        switch selectedSort {
        case .priority:
            return tasks.sorted { t1, t2 in
                if t1.priority != t2.priority {
                    return t1.priority.sortOrder < t2.priority.sortOrder
                }
                // A priorité égale, deadline la plus proche d'abord
                let d1 = t1.deadline ?? .distantFuture
                let d2 = t2.deadline ?? .distantFuture
                return d1 < d2
            }
        case .deadline:
            return tasks.sorted { t1, t2 in
                let d1 = t1.deadline ?? .distantFuture
                let d2 = t2.deadline ?? .distantFuture
                if d1 != d2 { return d1 < d2 }
                return t1.priority.sortOrder < t2.priority.sortOrder
            }
        case .creation:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            return tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    private var activeTasks: [MochiTask] {
        appState.tasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [MochiTask] {
        appState.tasks.filter { $0.isCompleted }
    }

    private var overdueTasks: [MochiTask] {
        appState.tasks.filter { $0.isOverdue }
    }

    private var completedTodayTasks: [MochiTask] {
        appState.tasks.filter {
            guard let completedAt = $0.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }
    }

    private var completionRate: Double {
        let total = appState.tasks.count
        guard total > 0 else { return 0 }
        return Double(completedTasks.count) / Double(total)
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        var task = MochiTask(title: title)
        task.deadline = newTaskDeadline
        appState.addTask(task)
        newTaskTitle = ""
        newTaskDeadline = nil
    }
}

#Preview {
    TasksTrackingView()
        .environmentObject(AppState())
        .frame(width: 900, height: 600)
        .background(MochiTheme.backgroundLight)
}

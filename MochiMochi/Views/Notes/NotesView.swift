import SwiftUI

struct QuickNote: Identifiable, Codable {
    let id: UUID
    var content: String
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), content: String = "", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct NotesView: View {
    @EnvironmentObject var appState: AppState
    @State private var notes: [QuickNote] = []
    @State private var selectedNoteId: UUID?
    @State private var editingContent: String = ""
    @State private var hoveredNoteId: UUID?
    @State private var isAnalyzing: Bool = false
    @State private var extractedTasks: [ExtractedTask] = []
    @State private var showExtractedTasks: Bool = false

    private let storageFile = "content/notes/quick-notes.json"

    var body: some View {
        HStack(spacing: 0) {
            notesList
                .frame(width: 260)

            Divider().opacity(0.3)

            if let noteId = selectedNoteId, let index = notes.firstIndex(where: { $0.id == noteId }) {
                noteEditor(index: index)
            } else {
                emptyEditor
            }
        }
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                .fill(MochiTheme.surfaceLight)
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous))
        .onAppear { loadNotes() }
        .sheet(isPresented: $showExtractedTasks) {
            ExtractedTasksSheet(
                tasks: $extractedTasks,
                onConfirm: { confirmed in
                    for task in confirmed {
                        let mochiTask = MochiTask(title: task.title, priority: task.priority)
                        appState.addTask(mochiTask)
                    }
                    showExtractedTasks = false
                    appState.setTemporaryEmotion(.happy, duration: 4)
                },
                onDismiss: {
                    showExtractedTasks = false
                }
            )
        }
    }

    // MARK: - Notes List

    private var notesList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Notes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MochiTheme.textLight)

                Text("\(notes.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MochiTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(MochiTheme.primary.opacity(0.15)))

                Spacer()

                Button { addNote() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MochiTheme.primary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(MochiTheme.primary.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().opacity(0.3)

            if notes.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "note.text")
                        .font(.system(size: 28))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.2))
                    Text("Aucune note")
                        .font(.system(size: 13))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                    Text("Clique + pour commencer")
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(notes) { note in
                            noteRow(note)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func noteRow(_ note: QuickNote) -> some View {
        let isSelected = selectedNoteId == note.id
        let isHovered = hoveredNoteId == note.id

        return Button {
            selectNote(note)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(noteTitle(note))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MochiTheme.textLight)
                    .lineLimit(1)

                Text(notePreview(note))
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                    .lineLimit(2)

                Text(relativeDate(note.updatedAt))
                    .font(.system(size: 10))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.3))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isSelected
                            ? MochiTheme.primary.opacity(0.1)
                            : (isHovered ? Color.gray.opacity(0.05) : Color.clear)
                    )
            )
            .overlay(alignment: .trailing) {
                if isHovered {
                    Button {
                        deleteNote(note)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red.opacity(0.6))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 10)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredNoteId = hovering ? note.id : nil
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Editor

    private func noteEditor(index: Int) -> some View {
        VStack(spacing: 0) {
            // Editor header
            HStack {
                Text(relativeDate(notes[index].updatedAt))
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))

                Spacer()

                // Analyse button
                Button {
                    Task { await analyzeNote() }
                } label: {
                    HStack(spacing: 6) {
                        if isAnalyzing {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 12))
                        }
                        Text(isAnalyzing ? "Analyse..." : "Extraire les taches")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(isAnalyzing ? MochiTheme.textLight.opacity(0.5) : MochiTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isAnalyzing ? Color.gray.opacity(0.08) : MochiTheme.primary.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(isAnalyzing ? Color.gray.opacity(0.1) : MochiTheme.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isAnalyzing || editingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider().opacity(0.2)

            TextEditor(text: $editingContent)
                .font(.system(size: 14))
                .foregroundStyle(MochiTheme.textLight)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: editingContent) { _, newValue in
                    guard selectedNoteId == notes[index].id else { return }
                    notes[index].content = newValue
                    notes[index].updatedAt = Date()
                    saveNotesDebounced()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyEditor: some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 36))
                .foregroundStyle(MochiTheme.textLight.opacity(0.15))
            Text("Selectionne ou cree une note")
                .font(.system(size: 14))
                .foregroundStyle(MochiTheme.textLight.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Analyze Note

    private func analyzeNote() async {
        let content = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isAnalyzing = true
        appState.setTemporaryEmotion(.thinking)

        let prompt = """
        Analyse cette note et extrais TOUTES les taches actionnables.
        Pour chaque tache, reponds avec une ligne au format :
        [TASK:titre de la tache] pour priorite normale
        [TASK_HIGH:titre] pour une tache urgente/importante
        [TASK_LOW:titre] pour une tache secondaire/plus tard

        Reponds UNIQUEMENT avec les marqueurs [TASK...], un par ligne, rien d'autre.
        Si la note ne contient aucune tache actionnable, reponds : [AUCUNE]

        Note a analyser :
        ---
        \(content)
        ---
        """

        do {
            let response = try await appState.claudeCodeService.send(
                message: prompt,
                workingDirectory: appState.storageDirectory
            )
            let tasks = parseExtractedTasks(from: response)

            await MainActor.run {
                isAnalyzing = false
                if tasks.isEmpty {
                    appState.setTemporaryEmotion(.idle, duration: 3)
                } else {
                    extractedTasks = tasks
                    showExtractedTasks = true
                    appState.setTemporaryEmotion(.proud, duration: 4)
                }
            }
        } catch {
            await MainActor.run {
                isAnalyzing = false
                appState.setTemporaryEmotion(.worried, duration: 4)
            }
        }
    }

    private func parseExtractedTasks(from response: String) -> [ExtractedTask] {
        var tasks: [ExtractedTask] = []
        let lines = response.components(separatedBy: "\n")
        let pattern = /\[TASK(?:_(HIGH|LOW))?:(.+?)\]/

        for line in lines {
            if let match = line.firstMatch(of: pattern) {
                let priorityStr = match.1.map { String($0) }
                let title = String(match.2).trimmingCharacters(in: .whitespaces)
                guard !title.isEmpty else { continue }

                let priority: TaskPriority
                switch priorityStr {
                case "HIGH": priority = .high
                case "LOW": priority = .low
                default: priority = .normal
                }

                tasks.append(ExtractedTask(title: title, priority: priority))
            }
        }
        return tasks
    }

    // MARK: - Actions

    private func addNote() {
        let note = QuickNote()
        notes.insert(note, at: 0)
        selectNote(note)
        saveNotes()
    }

    private func selectNote(_ note: QuickNote) {
        selectedNoteId = note.id
        editingContent = note.content
    }

    private func deleteNote(_ note: QuickNote) {
        if selectedNoteId == note.id {
            selectedNoteId = nil
            editingContent = ""
        }
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }

    // MARK: - Persistence

    @State private var pendingSave: DispatchWorkItem?

    private func saveNotesDebounced() {
        pendingSave?.cancel()
        let item = DispatchWorkItem { [notes] in
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? encoder.encode(notes),
                  let json = String(data: data, encoding: .utf8) else { return }
            try? appState.memoryService.storage.write(file: storageFile, content: json)
        }
        pendingSave = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
    }

    private func saveNotes() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(notes),
              let json = String(data: data, encoding: .utf8) else { return }
        try? appState.memoryService.storage.write(file: storageFile, content: json)
    }

    private func loadNotes() {
        guard let json = appState.memoryService.storage.read(file: storageFile),
              let data = json.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let loaded = try? decoder.decode([QuickNote].self, from: data) {
            notes = loaded.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    // MARK: - Helpers

    private func noteTitle(_ note: QuickNote) -> String {
        let firstLine = note.content.components(separatedBy: "\n").first ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Note sans titre" : String(trimmed.prefix(50))
    }

    private func notePreview(_ note: QuickNote) -> String {
        let lines = note.content.components(separatedBy: "\n").dropFirst()
        let preview = lines.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return preview.isEmpty ? "" : String(preview.prefix(80))
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Extracted Task Model

struct ExtractedTask: Identifiable {
    let id = UUID()
    var title: String
    var priority: TaskPriority
    var isSelected: Bool = true
}

// MARK: - Extracted Tasks Confirmation Sheet

struct ExtractedTasksSheet: View {
    @Binding var tasks: [ExtractedTask]
    let onConfirm: ([ExtractedTask]) -> Void
    let onDismiss: () -> Void

    private var selectedCount: Int {
        tasks.filter(\.isSelected).count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Taches extraites")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MochiTheme.textLight)
                    Text("\(tasks.count) tache\(tasks.count > 1 ? "s" : "") trouvee\(tasks.count > 1 ? "s" : "")")
                        .font(.system(size: 12))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                }
                Spacer()
                Button { onDismiss() } label: {
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

            Divider().opacity(0.3)

            // Task list
            ScrollView {
                VStack(spacing: 4) {
                    ForEach($tasks) { $task in
                        extractedTaskRow(task: $task)
                    }
                }
                .padding(16)
            }

            Divider().opacity(0.3)

            // Footer
            HStack {
                Button {
                    let allSelected = tasks.allSatisfy(\.isSelected)
                    for i in tasks.indices {
                        tasks[i].isSelected = !allSelected
                    }
                } label: {
                    Text(tasks.allSatisfy(\.isSelected) ? "Tout deselectionner" : "Tout selectionner")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MochiTheme.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button { onDismiss() } label: {
                    Text("Annuler")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                Button {
                    onConfirm(tasks.filter(\.isSelected))
                } label: {
                    Text("Ajouter \(selectedCount) tache\(selectedCount > 1 ? "s" : "")")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(
                                selectedCount > 0
                                    ? MochiTheme.primary
                                    : MochiTheme.primary.opacity(0.4)
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedCount == 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 440, height: min(CGFloat(tasks.count) * 60 + 160, 500))
        .background(Color.white)
    }

    private func extractedTaskRow(task: Binding<ExtractedTask>) -> some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                task.wrappedValue.isSelected.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            task.wrappedValue.isSelected ? MochiTheme.primary : Color.gray.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 18, height: 18)

                    if task.wrappedValue.isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MochiTheme.primary)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                }
            }
            .buttonStyle(.plain)

            // Title
            Text(task.wrappedValue.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    task.wrappedValue.isSelected
                        ? MochiTheme.textLight
                        : MochiTheme.textLight.opacity(0.4)
                )
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Priority pill
            Text(task.wrappedValue.priority.displayName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(priorityColor(task.wrappedValue.priority))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(priorityColor(task.wrappedValue.priority).opacity(0.12))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(task.wrappedValue.isSelected ? Color.gray.opacity(0.04) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return MochiTheme.errorRed
        case .normal: return MochiTheme.secondary
        case .low: return MochiTheme.priorityLow
        }
    }
}

#Preview {
    NotesView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}

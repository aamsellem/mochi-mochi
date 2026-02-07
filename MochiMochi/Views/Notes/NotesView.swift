import SwiftUI

// MARK: - NoteCategory

enum NoteCategory: String, Codable, CaseIterable {
    case meeting
    case idea
    case technique
    case personal

    var displayName: String {
        switch self {
        case .meeting: return "Reunion"
        case .idea: return "Idee"
        case .technique: return "Technique"
        case .personal: return "Perso"
        }
    }

    var icon: String {
        switch self {
        case .meeting: return "person.2"
        case .idea: return "lightbulb"
        case .technique: return "wrench.and.screwdriver"
        case .personal: return "heart"
        }
    }

    var color: Color {
        switch self {
        case .meeting: return MochiTheme.pastelGreen
        case .idea: return MochiTheme.pastelYellow
        case .technique: return MochiTheme.pastelBlue
        case .personal: return MochiTheme.accent
        }
    }
}

// MARK: - QuickNote Model

struct QuickNote: Identifiable, Codable {
    let id: UUID
    var content: String
    let createdAt: Date
    var updatedAt: Date
    var isPinned: Bool?
    var category: NoteCategory?
    var tags: [String]?
    var summary: String?

    init(id: UUID = UUID(), content: String = "", createdAt: Date = Date(), updatedAt: Date = Date(),
         isPinned: Bool? = nil, category: NoteCategory? = nil, tags: [String]? = nil, summary: String? = nil) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.category = category
        self.tags = tags
        self.summary = summary
    }
}

// MARK: - NotesView

struct NotesView: View {
    @EnvironmentObject var appState: AppState
    @State private var notes: [QuickNote] = []
    @State private var selectedNoteId: UUID?
    @State private var editingContent: String = ""
    @State private var hoveredNoteId: UUID?
    @State private var isAnalyzing: Bool = false
    @State private var extractedTasks: [ExtractedTask] = []
    @State private var showExtractedTasks: Bool = false

    // New states
    @State private var searchText: String = ""
    @State private var selectedCategory: NoteCategory?
    @State private var isSummarizing: Bool = false
    @State private var isRewriting: Bool = false
    @State private var isGeneratingCR: Bool = false
    @State private var isAutoTagging: Bool = false
    @State private var aiQuestion: String = ""
    @State private var aiAnswer: String = ""
    @State private var showAIAnswer: Bool = false
    @State private var showMarkdownPreview: Bool = false

    private let storageFile = "content/notes/quick-notes.json"

    private var anyAIRunning: Bool {
        isAnalyzing || isSummarizing || isRewriting || isGeneratingCR || isAutoTagging
    }

    private var displayedNotes: [QuickNote] {
        var filtered = notes

        if let cat = selectedCategory {
            filtered = filtered.filter { $0.category == cat }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { note in
                note.content.lowercased().contains(query)
                || (note.tags ?? []).contains { $0.lowercased().contains(query) }
                || (note.summary ?? "").lowercased().contains(query)
            }
        }

        return filtered.sorted { a, b in
            let aPinned = a.isPinned ?? false
            let bPinned = b.isPinned ?? false
            if aPinned != bPinned { return aPinned }
            return a.updatedAt > b.updatedAt
        }
    }

    private var wordCharCount: (words: Int, chars: Int) {
        let text = editingContent
        let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        let chars = text.count
        return (words, chars)
    }

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
        .sheet(isPresented: $showAIAnswer) {
            AIAnswerSheet(answer: aiAnswer) {
                showAIAnswer = false
            }
        }
    }

    // MARK: - Notes List (Sidebar)

    private var notesList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MochiTheme.textLight)

                Text("\(displayedNotes.count)")
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

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                TextField("Rechercher...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(MochiTheme.textLight)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.06))
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            // Category pills (2 rows)
            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    categoryPill(nil, label: "Toutes", icon: "tray.full")
                    categoryPill(.meeting, label: NoteCategory.meeting.displayName, icon: NoteCategory.meeting.icon)
                    categoryPill(.idea, label: NoteCategory.idea.displayName, icon: NoteCategory.idea.icon)
                }
                HStack(spacing: 5) {
                    categoryPill(.technique, label: NoteCategory.technique.displayName, icon: NoteCategory.technique.icon)
                    categoryPill(.personal, label: NoteCategory.personal.displayName, icon: NoteCategory.personal.icon)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider().opacity(0.3)

            if displayedNotes.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "note.text")
                        .font(.system(size: 28))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.2))
                    Text(searchText.isEmpty && selectedCategory == nil ? "Aucune note" : "Aucun resultat")
                        .font(.system(size: 13))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                    Text(searchText.isEmpty && selectedCategory == nil ? "Clique + pour commencer" : "Essaie un autre filtre")
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(displayedNotes) { note in
                            noteRow(note)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func categoryPill(_ category: NoteCategory?, label: String, icon: String) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? MochiTheme.textLight : MochiTheme.textLight.opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(
                    isSelected
                        ? (category?.color ?? MochiTheme.primary).opacity(0.2)
                        : Color.gray.opacity(0.06)
                )
            )
        }
        .buttonStyle(.plain)
    }

    private func noteRow(_ note: QuickNote) -> some View {
        let isSelected = selectedNoteId == note.id
        let isHovered = hoveredNoteId == note.id
        let pinned = note.isPinned ?? false

        return Button {
            selectNote(note)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if pinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(MochiTheme.primary)
                    }
                    Text(noteTitle(note))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(MochiTheme.textLight)
                        .lineLimit(1)

                    Spacer()

                    if let cat = note.category {
                        Image(systemName: cat.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(cat.color.opacity(0.8))
                            .padding(4)
                            .background(Circle().fill(cat.color.opacity(0.2)))
                    }
                }

                Text(notePreview(note))
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(relativeDate(note.updatedAt))
                        .font(.system(size: 10))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.3))

                    if let tags = note.tags, !tags.isEmpty {
                        ForEach(tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(MochiTheme.secondary.opacity(0.7))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule().fill(MochiTheme.secondary.opacity(0.08))
                                )
                        }
                        if tags.count > 2 {
                            Text("+\(tags.count - 2)")
                                .font(.system(size: 9))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                        }
                    }
                }
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
                    VStack(spacing: 4) {
                        Button {
                            togglePin(note)
                        } label: {
                            Image(systemName: pinned ? "pin.slash" : "pin")
                                .font(.system(size: 10))
                                .foregroundStyle(MochiTheme.primary.opacity(0.7))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.white))
                        }
                        .buttonStyle(.plain)

                        Button {
                            deleteNote(note)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundStyle(.red.opacity(0.6))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.white))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing, 8)
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
            // Toolbar line 1: date | category | markdown toggle | word count
            HStack(spacing: 12) {
                Text(relativeDate(notes[index].updatedAt))
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))

                Divider().frame(height: 14)

                // Category menu
                Menu {
                    Button("Aucune") { setCategory(nil, at: index) }
                    Divider()
                    ForEach(NoteCategory.allCases, id: \.self) { cat in
                        Button {
                            setCategory(cat, at: index)
                        } label: {
                            Label(cat.displayName, systemImage: cat.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let cat = notes[index].category {
                            Image(systemName: cat.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(cat.color)
                            Text(cat.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                        } else {
                            Image(systemName: "tag")
                                .font(.system(size: 10))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                            Text("Categorie")
                                .font(.system(size: 11))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.gray.opacity(0.06))
                    )
                }
                .menuStyle(.borderlessButton)

                Spacer()

                // Markdown preview toggle
                Button {
                    showMarkdownPreview.toggle()
                } label: {
                    Image(systemName: showMarkdownPreview ? "doc.plaintext" : "doc.richtext")
                        .font(.system(size: 12))
                        .foregroundStyle(showMarkdownPreview ? MochiTheme.primary : MochiTheme.textLight.opacity(0.4))
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(showMarkdownPreview ? MochiTheme.primary.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help(showMarkdownPreview ? "Mode edition" : "Apercu Markdown")

                // Word/char count
                Text("\(wordCharCount.words) mots · \(wordCharCount.chars) car.")
                    .font(.system(size: 10))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.3))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

            // Toolbar line 2: AI buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    aiToolbarButton(
                        label: "Resumer", icon: "text.quote", isLoading: isSummarizing
                    ) {
                        Task { await summarizeNote() }
                    }
                    aiToolbarButton(
                        label: "Reformuler", icon: "arrow.triangle.2.circlepath", isLoading: isRewriting
                    ) {
                        Task { await rewriteNote() }
                    }
                    aiToolbarButton(
                        label: "Compte-rendu", icon: "doc.text", isLoading: isGeneratingCR
                    ) {
                        Task { await generateMeetingMinutes() }
                    }
                    aiToolbarButton(
                        label: "Auto-tag", icon: "number", isLoading: isAutoTagging
                    ) {
                        Task { await autoTagNote() }
                    }
                    aiToolbarButton(
                        label: "Extraire taches", icon: "wand.and.stars", isLoading: isAnalyzing
                    ) {
                        Task { await analyzeNote() }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 8)

            Divider().opacity(0.2)

            // Summary banner
            if let summary = notes[index].summary, !summary.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.primary)
                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.7))
                        .lineLimit(2)
                    Spacer()
                    Button {
                        notes[index].summary = nil
                        saveNotes()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(MochiTheme.primary.opacity(0.04))
            }

            // Tags display
            if let tags = notes[index].tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(MochiTheme.secondary)
                                Button {
                                    removeTag(tag, at: index)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(MochiTheme.secondary.opacity(0.5))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(MochiTheme.secondary.opacity(0.08))
                                    .overlay(Capsule().stroke(MochiTheme.secondary.opacity(0.15), lineWidth: 1))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 6)
            }

            // Editor body: TextEditor or Markdown preview
            if showMarkdownPreview {
                ScrollView {
                    markdownRendered(editingContent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
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

            Divider().opacity(0.2)

            // "Ask Mochi" bar
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble")
                    .font(.system(size: 12))
                    .foregroundStyle(MochiTheme.primary.opacity(0.5))
                TextField("Demande a Mochi...", text: $aiQuestion)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(MochiTheme.textLight)
                    .onSubmit {
                        Task { await askAboutNote() }
                    }
                if !aiQuestion.isEmpty {
                    Button {
                        Task { await askAboutNote() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(MochiTheme.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(anyAIRunning)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func aiToolbarButton(label: String, icon: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(isLoading ? "\(label)..." : label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isLoading ? MochiTheme.textLight.opacity(0.5) : MochiTheme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isLoading ? Color.gray.opacity(0.08) : MochiTheme.primary.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(isLoading ? Color.gray.opacity(0.1) : MochiTheme.primary.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(anyAIRunning || editingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    // MARK: - Markdown Renderer

    private enum MarkdownBlock {
        case heading(level: Int, text: String)
        case paragraph(text: String)
        case codeBlock(code: String)
        case horizontalRule
        case orderedList(items: [String])
        case unorderedList(items: [String])
    }

    @ViewBuilder
    private func markdownRendered(_ content: String) -> some View {
        let blocks = parseMarkdown(content)
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let level, let text):
                    markdownHeading(level: level, text: text)

                case .paragraph(let text):
                    markdownInlineText(text)
                        .foregroundStyle(MochiTheme.textLight)

                case .codeBlock(let code):
                    Text(code)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(MochiTheme.codeText)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(MochiTheme.codeBackground)
                        )

                case .horizontalRule:
                    Rectangle()
                        .fill(MochiTheme.primary.opacity(0.25))
                        .frame(height: 1.5)
                        .padding(.vertical, 4)

                case .orderedList(let items):
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(idx + 1).")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(MochiTheme.primary)
                                    .frame(width: 22, alignment: .trailing)
                                markdownInlineText(item)
                                    .foregroundStyle(MochiTheme.textLight)
                            }
                        }
                    }
                    .padding(.leading, 4)

                case .unorderedList(let items):
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(MochiTheme.primary)
                                    .frame(width: 6, height: 6)
                                    .offset(y: 6)
                                markdownInlineText(item)
                                    .foregroundStyle(MochiTheme.textLight)
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
            }
        }
    }

    @ViewBuilder
    private func markdownHeading(level: Int, text: String) -> some View {
        let size: CGFloat = level == 1 ? 18 : (level == 2 ? 15 : 13)
        HStack(spacing: 8) {
            if level == 1 {
                RoundedRectangle(cornerRadius: 2)
                    .fill(MochiTheme.primary)
                    .frame(width: 4, height: size + 4)
            }
            markdownInlineText(text)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(level == 1 ? MochiTheme.primary : MochiTheme.textLight)
        }
        .padding(.top, level == 1 ? 4 : 2)
    }

    private func markdownInlineText(_ string: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: string,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributed)
        }
        return Text(string)
    }

    private func parseMarkdown(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0
        var paragraphLines: [String] = []

        func flushParagraph() {
            let joined = paragraphLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty {
                blocks.append(.paragraph(text: joined))
            }
            paragraphLines = []
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code block
            if trimmed.hasPrefix("```") {
                flushParagraph()
                i += 1
                var codeLines: [String] = []
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(code: codeLines.joined(separator: "\n")))
                if i < lines.count { i += 1 }
                continue
            }

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph()
                blocks.append(.horizontalRule)
                i += 1
                continue
            }

            // Heading
            if let match = trimmed.wholeMatch(of: /^(#{1,3})\s+(.+)/) {
                flushParagraph()
                blocks.append(.heading(level: match.1.count, text: String(match.2)))
                i += 1
                continue
            }

            // Ordered list
            if trimmed.wholeMatch(of: /^\d+\.\s+.+/) != nil {
                flushParagraph()
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if let m = l.wholeMatch(of: /^\d+\.\s+(.+)/) {
                        items.append(String(m.1))
                        i += 1
                    } else if l.isEmpty && i + 1 < lines.count &&
                                lines[i + 1].trimmingCharacters(in: .whitespaces).wholeMatch(of: /^\d+\.\s+.+/) != nil {
                        i += 1
                    } else {
                        break
                    }
                }
                blocks.append(.orderedList(items: items))
                continue
            }

            // Unordered list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushParagraph()
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix("- ") {
                        items.append(String(l.dropFirst(2)))
                        i += 1
                    } else if l.hasPrefix("* ") {
                        items.append(String(l.dropFirst(2)))
                        i += 1
                    } else if l.isEmpty && i + 1 < lines.count {
                        let next = lines[i + 1].trimmingCharacters(in: .whitespaces)
                        if next.hasPrefix("- ") || next.hasPrefix("* ") {
                            i += 1
                        } else {
                            break
                        }
                    } else {
                        break
                    }
                }
                blocks.append(.unorderedList(items: items))
                continue
            }

            // Empty line = paragraph break
            if trimmed.isEmpty {
                flushParagraph()
                i += 1
                continue
            }

            // Regular text
            paragraphLines.append(line)
            i += 1
        }

        flushParagraph()
        return blocks
    }

    // MARK: - AI Functions

    private func summarizeNote() async {
        let content = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isSummarizing = true
        appState.setTemporaryEmotion(.thinking)

        let prompt = """
        Resume cette note en 2-3 phrases concises. Garde les points essentiels.
        Reponds UNIQUEMENT avec le resume, sans prefixe ni explication.

        Note :
        ---
        \(content)
        ---
        """

        do {
            let response = try await appState.claudeCodeService.send(
                message: prompt,
                workingDirectory: appState.storageDirectory
            )
            await MainActor.run {
                isSummarizing = false
                if let index = notes.firstIndex(where: { $0.id == selectedNoteId }) {
                    notes[index].summary = response.trimmingCharacters(in: .whitespacesAndNewlines)
                    saveNotes()
                }
                appState.setTemporaryEmotion(.happy, duration: 3)
            }
        } catch {
            await MainActor.run {
                isSummarizing = false
                appState.setTemporaryEmotion(.worried, duration: 4)
            }
        }
    }

    private func rewriteNote() async {
        let content = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isRewriting = true
        appState.setTemporaryEmotion(.thinking)

        let prompt = """
        Reformule et ameliore cette note. Garde le meme sens mais rends le texte plus clair,
        mieux structure et plus professionnel. Utilise du Markdown si pertinent.
        Reponds UNIQUEMENT avec la note reformulee, sans prefixe ni explication.

        Note originale :
        ---
        \(content)
        ---
        """

        do {
            let response = try await appState.claudeCodeService.send(
                message: prompt,
                workingDirectory: appState.storageDirectory
            )
            await MainActor.run {
                isRewriting = false
                editingContent = response.trimmingCharacters(in: .whitespacesAndNewlines)
                appState.setTemporaryEmotion(.proud, duration: 4)
            }
        } catch {
            await MainActor.run {
                isRewriting = false
                appState.setTemporaryEmotion(.worried, duration: 4)
            }
        }
    }

    private func generateMeetingMinutes() async {
        let content = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isGeneratingCR = true
        appState.setTemporaryEmotion(.thinking)

        let prompt = """
        A partir de ces notes de reunion, genere un compte-rendu structure en Markdown avec :
        - Titre et date
        - Participants (si mentionnes)
        - Points discutes
        - Decisions prises
        - Actions a mener (avec responsable si possible)

        Reponds UNIQUEMENT avec le compte-rendu Markdown, sans prefixe.

        Notes de reunion :
        ---
        \(content)
        ---
        """

        do {
            let response = try await appState.claudeCodeService.send(
                message: prompt,
                workingDirectory: appState.storageDirectory
            )
            await MainActor.run {
                isGeneratingCR = false
                // Create a new note with the meeting minutes
                var crNote = QuickNote(content: response.trimmingCharacters(in: .whitespacesAndNewlines))
                crNote.category = .meeting
                notes.insert(crNote, at: 0)
                selectNote(crNote)
                saveNotes()
                appState.setTemporaryEmotion(.proud, duration: 4)
            }
        } catch {
            await MainActor.run {
                isGeneratingCR = false
                appState.setTemporaryEmotion(.worried, duration: 4)
            }
        }
    }

    private func autoTagNote() async {
        let content = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isAutoTagging = true
        appState.setTemporaryEmotion(.thinking)

        let prompt = """
        Analyse cette note et propose 3 a 5 tags pertinents.
        Reponds UNIQUEMENT avec les tags separes par des virgules, sans prefixe ni explication.
        Exemple : swift, architecture, refactoring

        Note :
        ---
        \(content)
        ---
        """

        do {
            let response = try await appState.claudeCodeService.send(
                message: prompt,
                workingDirectory: appState.storageDirectory
            )
            await MainActor.run {
                isAutoTagging = false
                let tags = response
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }

                if let index = notes.firstIndex(where: { $0.id == selectedNoteId }) {
                    notes[index].tags = tags
                    saveNotes()
                }
                appState.setTemporaryEmotion(.happy, duration: 3)
            }
        } catch {
            await MainActor.run {
                isAutoTagging = false
                appState.setTemporaryEmotion(.worried, duration: 4)
            }
        }
    }

    private func askAboutNote() async {
        let question = aiQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !content.isEmpty else { return }

        let savedQuestion = aiQuestion
        aiQuestion = ""
        appState.setTemporaryEmotion(.thinking)

        let prompt = """
        L'utilisateur pose une question a propos de sa note.

        Question : \(savedQuestion)

        Note :
        ---
        \(content)
        ---

        Reponds de maniere concise et utile.
        """

        do {
            let response = try await appState.claudeCodeService.send(
                message: prompt,
                workingDirectory: appState.storageDirectory
            )
            await MainActor.run {
                aiAnswer = response.trimmingCharacters(in: .whitespacesAndNewlines)
                showAIAnswer = true
                appState.setTemporaryEmotion(.happy, duration: 3)
            }
        } catch {
            await MainActor.run {
                appState.setTemporaryEmotion(.worried, duration: 4)
            }
        }
    }

    // MARK: - Analyze Note (existing)

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

    private func togglePin(_ note: QuickNote) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        let current = notes[index].isPinned ?? false
        notes[index].isPinned = !current
        saveNotes()
    }

    private func setCategory(_ category: NoteCategory?, at index: Int) {
        notes[index].category = category
        notes[index].updatedAt = Date()
        saveNotes()
    }

    private func removeTag(_ tag: String, at index: Int) {
        notes[index].tags?.removeAll { $0 == tag }
        if notes[index].tags?.isEmpty == true {
            notes[index].tags = nil
        }
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

// MARK: - AI Answer Sheet

struct AIAnswerSheet: View {
    let answer: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(MochiTheme.primary)
                    Text("Reponse de Mochi")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MochiTheme.textLight)
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

            ScrollView {
                Text(answer)
                    .font(.system(size: 13))
                    .foregroundStyle(MochiTheme.textLight)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
        .frame(width: 440, height: 300)
        .background(Color.white)
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

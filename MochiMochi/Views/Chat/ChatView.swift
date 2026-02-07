import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText = ""
    @State private var showSlashMenu = false
    @State private var thinkingBounce = false
    @State private var pendingAttachments: [Attachment] = []
    @State private var inputHistory: [String] = []
    @State private var historyIndex: Int = -1
    @State private var isNavigatingHistory = false
    @State private var selectedCommandIndex: Int = 0
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            Divider()
            messagesArea
            inputBar
        }
        .background(MochiTheme.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous))
        .onChange(of: appState.isRecordingVoice) { wasRecording, isRecording in
            // Auto-insert transcribed text when recording stops (e.g. silence timeout)
            if wasRecording && !isRecording {
                let transcribed = appState.voiceTranscription
                if !transcribed.isEmpty {
                    if inputText.isEmpty {
                        inputText = transcribed
                    } else {
                        inputText += " " + transcribed
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Chat")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(MochiTheme.textLight)
                Text("Assistant IA \u{2022} En ligne")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                headerButton(icon: "clock.arrow.circlepath")
                headerButton(icon: "ellipsis")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(MochiTheme.surfaceLight)
    }

    private func headerButton(icon: String) -> some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MochiTheme.textLight)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            // hover effect handled via NSCursor if needed
        }
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if appState.messages.isEmpty {
                        emptyState
                    }

                    ForEach(appState.messages) { message in
                        chatBubble(for: message)
                            .id(message.id)
                    }

                    if appState.isLoading {
                        loadingIndicator
                            .id("loading")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: appState.messages.count) { _, _ in
                if let lastMessage = appState.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: appState.isLoading) { _, isLoading in
                if isLoading {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Bienvenue ! Ecris un message ou utilise une /commande")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var loadingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Mini Mochi avatar
            MochiAvatarView(
                emotion: .thinking,
                color: appState.mochi.color,
                equippedItems: appState.mochi.equippedItems,
                size: 40
            )

            // Bulle de reflexion (calme)
            VStack(alignment: .leading, spacing: 6) {
                Text(appState.mochi.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MochiTheme.primary)

                HStack(spacing: 5) {
                    Text("reflechit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(MochiTheme.primary.opacity(0.6))
                                .frame(width: 5, height: 5)
                                .opacity(thinkingBounce ? 1.0 : 0.25)
                                .animation(
                                    .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.3),
                                    value: thinkingBounce
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 4,
                    bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: 16
                )
                .fill(MochiTheme.primary.opacity(0.08))
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 4,
                        bottomLeadingRadius: 16,
                        bottomTrailingRadius: 16,
                        topTrailingRadius: 16
                    )
                    .stroke(MochiTheme.primary.opacity(0.2), lineWidth: 1)
                )
            )

            Spacer(minLength: 30)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { thinkingBounce = true }
        .onDisappear { thinkingBounce = false }
    }

    // MARK: - Chat Bubble

    @ViewBuilder
    private func chatBubble(for message: Message) -> some View {
        let isUser = message.role == .user

        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 40)
            } else {
                // Mochi avatar badge
                Text(String(appState.mochi.name.prefix(1)).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(MochiTheme.secondary))
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if isUser {
                    userBubbleContent(message)
                } else {
                    assistantBubbleContent(message)
                }

                // Timestamp
                Text(formattedTime(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.gray.opacity(0.6))
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: isUser
                   ? UIConstants.userMaxWidthFraction
                   : UIConstants.assistantMaxWidthFraction,
                   alignment: isUser ? .trailing : .leading)

            if !isUser {
                Spacer(minLength: 30)
            }
        }
    }

    private func userBubbleContent(_ message: Message) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            if !message.attachments.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(message.attachments) { attachment in
                        attachmentChip(attachment, light: true)
                    }
                }
            }
            if !message.content.isEmpty {
                Text(message.content)
                    .textSelection(.enabled)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 20,
                topTrailingRadius: 4
            )
            .fill(MochiTheme.primary)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private func assistantBubbleContent(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(appState.mochi.name)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(MochiTheme.primary)

            formattedAssistantText(message.content)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 4,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 20,
                topTrailingRadius: 20
            )
            .fill(Color.gray.opacity(0.05))
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 4,
                    bottomLeadingRadius: 20,
                    bottomTrailingRadius: 20,
                    topTrailingRadius: 20
                )
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        )
    }

    // MARK: - Markdown Rendering

    private enum MarkdownBlock {
        case heading(level: Int, text: String)
        case paragraph(text: String)
        case codeBlock(code: String)
        case horizontalRule
        case orderedList(items: [String])
        case unorderedList(items: [String])
    }

    @ViewBuilder
    private func formattedAssistantText(_ content: String) -> some View {
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
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
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

    // MARK: - Input Bar

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pendingAttachments.isEmpty
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Pending attachments chips
            if !pendingAttachments.isEmpty {
                pendingAttachmentsBar
            }

            // Transcription feedback
            if appState.isRecordingVoice {
                transcriptionBar
            }

            HStack(alignment: .center, spacing: 10) {
                // Plus button — file upload
                Button(action: openFilePanel) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.gray)
                }
                .buttonStyle(.plain)

                // Text field
                ZStack(alignment: .leading) {
                    if inputText.isEmpty {
                        Text("Tape un message ou une commande...")
                            .font(.body)
                            .foregroundStyle(MochiTheme.textPlaceholder)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $inputText, axis: .vertical)
                        .font(.body)
                        .foregroundStyle(MochiTheme.textLight)
                        .lineLimit(1...6)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                }
                    .onKeyPress(.upArrow) { handleUpArrow() }
                    .onKeyPress(.downArrow) { handleDownArrow() }
                    .onKeyPress(.return) { handleReturn() }
                    .onKeyPress(.escape) { handleEscape() }
                    .onKeyPress(.tab) { handleTab() }
                    .onSubmit { sendIfReady() }
                    .onChange(of: inputText) { _, newValue in
                        if !isNavigatingHistory {
                            historyIndex = -1
                        }
                        isNavigatingHistory = false

                        let isSlashPrefix = newValue.hasPrefix("/") && !newValue.contains(" ")
                        showSlashMenu = isSlashPrefix
                        if isSlashPrefix {
                            selectedCommandIndex = 0
                        }
                    }

                // Microphone button
                Button(action: toggleRecording) {
                    Image(systemName: appState.isRecordingVoice ? "mic.fill" : "mic")
                        .font(.system(size: 16))
                        .foregroundStyle(appState.isRecordingVoice ? MochiTheme.primary : Color.gray)
                        .scaleEffect(appState.isRecordingVoice ? 1.15 : 1.0)
                        .animation(
                            appState.isRecordingVoice
                                ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                                : .default,
                            value: appState.isRecordingVoice
                        )
                }
                .buttonStyle(.plain)

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(canSend
                                      ? MochiTheme.primary
                                      : MochiTheme.primary.opacity(0.4))
                        )
                        .shadow(color: MochiTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadius2XL, style: .continuous)
                .fill(MochiTheme.backgroundLight)
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadius2XL, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(16)
        .overlay(alignment: .top) {
            if showSlashMenu {
                slashCommandMenu
                    .offset(y: -slashMenuHeight)
            }
        }
    }

    // MARK: - Pending Attachments

    private var pendingAttachmentsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(pendingAttachments) { attachment in
                    HStack(spacing: 6) {
                        Image(systemName: attachment.sfSymbolName)
                            .font(.system(size: 12))
                            .foregroundStyle(MochiTheme.primary)

                        Text(attachment.fileName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MochiTheme.textLight)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 120)

                        Button {
                            pendingAttachments.removeAll { $0.id == attachment.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(MochiTheme.primary.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(MochiTheme.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Transcription Feedback

    private var transcriptionBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            Text(appState.voiceTranscription.isEmpty
                 ? "Ecoute en cours..."
                 : appState.voiceTranscription)
                .font(.system(size: 13))
                .foregroundStyle(MochiTheme.textLight.opacity(0.7))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Attachment Chip (in bubbles)

    private func attachmentChip(_ attachment: Attachment, light: Bool) -> some View {
        Button {
            let fullPath = appState.memoryService.storage.baseDirectory
                .appendingPathComponent(attachment.filePath)
            NSWorkspace.shared.open(fullPath)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: attachment.sfSymbolName)
                    .font(.system(size: 11))
                Text(attachment.fileName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(light ? Color.white.opacity(0.2) : MochiTheme.primary.opacity(0.1))
            )
            .foregroundStyle(light ? .white : MochiTheme.textLight)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Slash Command Menu

    private let slashCommands: [(command: String, description: String)] = [
        ("/bonjour", "Briefing du jour"),
        ("/add", "Ajouter une tache"),
        ("/bilan", "Bilan de la journee"),
        ("/focus", "Mode concentration"),
        ("/pause", "Mettre en pause"),
        ("/objectif", "Gestion d'objectifs"),
        ("/humeur", "Changer de personnalite"),
        ("/inventaire", "Voir les items"),
        ("/boutique", "Ouvrir la boutique"),
        ("/stats", "Statistiques"),
        ("/notion", "Synchroniser Notion"),
        ("/help", "Aide"),
        ("/end", "Fin de session"),
    ]

    private var filteredCommands: [(command: String, description: String)] {
        let query = inputText.lowercased()
        if query == "/" { return slashCommands }
        return slashCommands.filter { $0.command.hasPrefix(query) }
    }

    private var slashMenuHeight: CGFloat {
        min(CGFloat(filteredCommands.count) * 32 + 16, 300)
    }

    @ViewBuilder
    private var slashCommandMenu: some View {
        let commands = filteredCommands
        let safeIndex = commands.isEmpty ? 0 : min(selectedCommandIndex, commands.count - 1)

        if !commands.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(commands.enumerated()), id: \.element.command) { index, item in
                                Button(action: {
                                    inputText = item.command + " "
                                    showSlashMenu = false
                                }) {
                                    HStack {
                                        Text(item.command)
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.medium)
                                            .foregroundStyle(index == safeIndex ? MochiTheme.primary : MochiTheme.textLight)
                                        Spacer()
                                        Text(item.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(index == safeIndex ? MochiTheme.primary.opacity(0.1) : Color.clear)
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .id(item.command)
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: selectedCommandIndex) { _, newIndex in
                        let clampedIndex = min(newIndex, commands.count - 1)
                        if clampedIndex >= 0 && clampedIndex < commands.count {
                            withAnimation(.easeOut(duration: 0.1)) {
                                proxy.scrollTo(commands[clampedIndex].command, anchor: .center)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 400, maxHeight: slashMenuHeight)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Key Handlers

    private func handleUpArrow() -> KeyPress.Result {
        // Slash menu: navigate up
        if showSlashMenu && !filteredCommands.isEmpty {
            selectedCommandIndex = max(0, selectedCommandIndex - 1)
            return .handled
        }
        // History: navigate backward
        if inputText.isEmpty && !inputHistory.isEmpty {
            isNavigatingHistory = true
            if historyIndex == -1 {
                historyIndex = inputHistory.count - 1
            } else if historyIndex > 0 {
                historyIndex -= 1
            }
            inputText = inputHistory[historyIndex]
            return .handled
        }
        return .ignored
    }

    private func handleDownArrow() -> KeyPress.Result {
        // Slash menu: navigate down
        if showSlashMenu && !filteredCommands.isEmpty {
            selectedCommandIndex = min(filteredCommands.count - 1, selectedCommandIndex + 1)
            return .handled
        }
        // History: navigate forward
        if historyIndex >= 0 {
            isNavigatingHistory = true
            if historyIndex < inputHistory.count - 1 {
                historyIndex += 1
                inputText = inputHistory[historyIndex]
            } else {
                historyIndex = -1
                inputText = ""
            }
            return .handled
        }
        return .ignored
    }

    private func handleReturn() -> KeyPress.Result {
        // Slash menu: select command
        if showSlashMenu && !filteredCommands.isEmpty {
            let safeIndex = min(selectedCommandIndex, filteredCommands.count - 1)
            let selected = filteredCommands[safeIndex]
            inputText = selected.command + " "
            showSlashMenu = false
            return .handled
        }
        return .ignored
    }

    private func handleEscape() -> KeyPress.Result {
        if showSlashMenu {
            showSlashMenu = false
            return .handled
        }
        if historyIndex >= 0 {
            historyIndex = -1
            inputText = ""
            return .handled
        }
        return .ignored
    }

    private func handleTab() -> KeyPress.Result {
        if showSlashMenu && !filteredCommands.isEmpty {
            let safeIndex = min(selectedCommandIndex, filteredCommands.count - 1)
            let selected = filteredCommands[safeIndex]
            inputText = selected.command + " "
            showSlashMenu = false
            return .handled
        }
        return .ignored
    }

    // MARK: - Actions

    private func sendIfReady() {
        guard canSend else { return }
        sendMessage()
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !pendingAttachments.isEmpty else { return }

        // Save to input history
        if !text.isEmpty && (inputHistory.isEmpty || inputHistory.last != text) {
            inputHistory.append(text)
        }
        historyIndex = -1

        let attachments = pendingAttachments
        inputText = ""
        pendingAttachments = []
        showSlashMenu = false

        // Stop recording if active
        if appState.isRecordingVoice {
            appState.speechService.stopRecording()
        }

        Task {
            await appState.sendMessage(text, attachments: attachments)
        }
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .pdf, .plainText, .image, .rtf, .spreadsheet,
            .json, .yaml, .xml, .html, .shellScript,
            .sourceCode, .swiftSource, .pythonScript,
        ]
        panel.message = "Choisis des fichiers a joindre au message"

        guard panel.runModal() == .OK else { return }

        let storage = appState.memoryService.storage
        for url in panel.urls {
            do {
                let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
                let fileType = UTType(filenameExtension: url.pathExtension)?.identifier ?? "public.data"
                let attachmentId = UUID()
                let destName = "\(attachmentId.uuidString)_\(url.lastPathComponent)"
                let destRelative = "attachments/\(destName)"
                let destURL = storage.baseDirectory.appendingPathComponent(destRelative)

                // Ensure attachments directory exists
                try FileManager.default.createDirectory(
                    at: storage.baseDirectory.appendingPathComponent("attachments"),
                    withIntermediateDirectories: true
                )
                try FileManager.default.copyItem(at: url, to: destURL)

                let attachment = Attachment(
                    id: attachmentId,
                    fileName: url.lastPathComponent,
                    fileType: fileType,
                    filePath: destRelative,
                    fileSize: fileSize
                )
                pendingAttachments.append(attachment)
            } catch {
                // Silently skip files that can't be copied
            }
        }
    }

    private func toggleRecording() {
        if appState.isRecordingVoice {
            appState.speechService.stopRecording()
            // Insert transcribed text into input
            let transcribed = appState.voiceTranscription
            if !transcribed.isEmpty {
                if inputText.isEmpty {
                    inputText = transcribed
                } else {
                    inputText += " " + transcribed
                }
            }
        } else {
            Task {
                let granted = await appState.speechService.requestPermissions()
                guard granted else { return }
                try? await appState.speechService.startRecording()
            }
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Constants

    private enum UIConstants {
        static let userMaxWidthFraction: CGFloat = 500
        static let assistantMaxWidthFraction: CGFloat = 600
    }
}

#Preview {
    ChatView()
        .environmentObject(AppState())
        .frame(width: 600, height: 700)
}

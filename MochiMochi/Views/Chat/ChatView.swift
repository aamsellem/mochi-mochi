import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText = ""
    @State private var showSlashMenu = false
    @State private var thinkingBounce = false
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
        HStack(spacing: 8) {
            // Mochi badge avec animation de pulse
            Text("M")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(MochiTheme.secondary))
                .scaleEffect(thinkingBounce ? 1.15 : 0.95)
                .animation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: thinkingBounce
                )

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(MochiTheme.secondary)
                        .frame(width: 7, height: 7)
                        .offset(y: thinkingBounce ? -4 : 4)
                        .animation(
                            .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                            value: thinkingBounce
                        )
                }
                Text("\(appState.mochi.name) reflechit...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(thinkingBounce ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: thinkingBounce
                    )
            }
        }
        .padding(.vertical, 8)
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
                Text("M")
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
        Text(message.content)
            .textSelection(.enabled)
            .foregroundStyle(.white)
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

    // MARK: - Formatted Assistant Text (Code Blocks)

    @ViewBuilder
    private func formattedAssistantText(_ content: String) -> some View {
        let blocks = parseCodeBlocks(content)
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                if block.isCode {
                    Text(block.text)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(MochiTheme.codeText)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(MochiTheme.codeBackground)
                        )
                } else {
                    Text(block.text)
                        .foregroundStyle(MochiTheme.textLight)
                }
            }
        }
    }

    private struct TextBlock {
        let text: String
        let isCode: Bool
    }

    private func parseCodeBlocks(_ text: String) -> [TextBlock] {
        var blocks: [TextBlock] = []
        let parts = text.components(separatedBy: "```")

        for (index, part) in parts.enumerated() {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if index % 2 == 1 {
                // Code block: strip optional language hint on first line
                let lines = trimmed.components(separatedBy: "\n")
                let codeContent = lines.count > 1
                    ? lines.dropFirst().joined(separator: "\n")
                    : trimmed
                blocks.append(TextBlock(text: codeContent, isCode: true))
            } else {
                blocks.append(TextBlock(text: trimmed, isCode: false))
            }
        }

        return blocks
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .center, spacing: 10) {
            // Plus button
            Button(action: {}) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.gray)
            }
            .buttonStyle(.plain)

            // Text field
            TextField("", text: $inputText, prompt: Text("Tape un message ou une commande...").foregroundColor(MochiTheme.textPlaceholder), axis: .vertical)
                .font(.body)
                .foregroundStyle(MochiTheme.textLight)
                .lineLimit(1...6)
                .textFieldStyle(.plain)
                .focused($isInputFocused)
                .onSubmit { sendIfReady() }
                .onChange(of: inputText) { _, newValue in
                    showSlashMenu = newValue.hasPrefix("/") && !newValue.contains(" ")
                }

            // Microphone button
            Button(action: {}) {
                Image(systemName: "mic")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.gray)
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
                            .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  ? MochiTheme.primary.opacity(0.4)
                                  : MochiTheme.primary)
                    )
                    .shadow(color: MochiTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(16)
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
        if !filteredCommands.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(filteredCommands, id: \.command) { item in
                            Button(action: {
                                inputText = item.command + " "
                                showSlashMenu = false
                            }) {
                                HStack {
                                    Text(item.command)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(item.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
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

    // MARK: - Actions

    private func sendIfReady() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        sendMessage()
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        showSlashMenu = false

        Task {
            await appState.sendMessage(text)
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

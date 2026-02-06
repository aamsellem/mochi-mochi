import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText = ""
    @State private var showSlashMenu = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        HSplitView {
            // Left: Chat messages (65%)
            chatPanel
                .frame(minWidth: 400)

            // Right: Mochi companion (35%)
            MochiView()
                .frame(minWidth: 220, idealWidth: 280, maxWidth: 350)
        }
    }

    // MARK: - Chat Panel

    private var chatPanel: some View {
        VStack(spacing: 0) {
            // Messages list
            messagesArea

            Divider()

            // Input bar
            inputBar
        }
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if appState.messages.isEmpty {
                        emptyState
                    }

                    ForEach(appState.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }

                    if appState.isLoading {
                        loadingIndicator
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
            Text("🍡")
                .font(.system(size: 48))
            Text("Bienvenue ! Ecris un message ou utilise une /commande")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var loadingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(0.4)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: appState.isLoading
                    )
            }
            Text("\(appState.mochi.name) reflechit...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Text editor for multi-line input
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Ecris un message ou une /commande...")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $inputText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 36, maxHeight: 120)
                    .fixedSize(horizontal: false, vertical: true)
                    .focused($isInputFocused)
                    .onSubmit { sendIfReady() }
                    .onChange(of: inputText) { _, newValue in
                        showSlashMenu = newValue.hasPrefix("/") && !newValue.contains(" ")
                    }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            // Send button
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
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
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accentColor.opacity(0.0))
                            )
                            .onHover { hovering in
                                // Visual hover handled by button highlight
                            }
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
}

#Preview {
    ChatView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}

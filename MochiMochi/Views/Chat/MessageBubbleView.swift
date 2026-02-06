import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    @State private var isHovering = false
    @State private var showCopied = false

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isUser ? AnyShapeStyle(userBubbleGradient) : AnyShapeStyle(Color(nsColor: .controlBackgroundColor)))
                    )
                    .foregroundStyle(isUser ? .white : .primary)

                // Timestamp + copy button
                HStack(spacing: 6) {
                    Text(formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if isHovering {
                        Button(action: copyToClipboard) {
                            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 60) }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - Helpers

    private var userBubbleGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }

    // MARK: - Actions

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopied = false
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubbleView(message: Message(role: .user, content: "Salut Mochi !"))
        MessageBubbleView(message: Message(role: .assistant, content: "Ohayo ! Comment vas-tu aujourd'hui ?"))
        MessageBubbleView(message: Message(role: .user, content: "/bonjour"))
        MessageBubbleView(message: Message(
            role: .assistant,
            content: "Voici ton briefing du jour :\n- 3 taches en cours\n- 1 deadline ce soir\n- Ton streak est a 8 jours !"
        ))
    }
    .padding()
    .frame(width: 500)
}

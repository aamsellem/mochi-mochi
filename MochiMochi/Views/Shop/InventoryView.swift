import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: ItemCategory = .color

    var body: some View {
        VStack(spacing: 0) {
            inventoryHeader
            Divider()

            categoryPicker
                .padding(.vertical, 8)

            if ownedItems.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
    }

    private var inventoryHeader: some View {
        HStack {
            Text("Inventaire")
                .font(.title2.bold())
                .foregroundStyle(MochiTheme.textLight)
            Spacer()
            Text("\(allOwnedItems.count) items")
                .font(.subheadline)
                .foregroundStyle(MochiTheme.textSecondary)
        }
        .padding()
    }

    private var categoryPicker: some View {
        HStack(spacing: 6) {
            ForEach(ItemCategory.allCases, id: \.self) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = category }
                } label: {
                    Text(category.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(selectedCategory == category ? MochiTheme.primary : Color.gray.opacity(0.08))
                        )
                        .foregroundStyle(selectedCategory == category ? .white : MochiTheme.textLight.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Aucun item dans cette categorie")
                .foregroundStyle(MochiTheme.textSecondary)
            Text("Visite la boutique pour debloquer des items !")
                .font(.caption)
                .foregroundStyle(MochiTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(ownedItems) { item in
                    InventoryItemRow(item: item) {
                        if item.category == .color {
                            appState.equipColor(item.name)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var ownedItems: [ShopItem] {
        appState.inventory.filter { $0.category == selectedCategory && $0.isOwned }
    }

    private var allOwnedItems: [ShopItem] {
        appState.inventory.filter { $0.isOwned }
    }
}

// MARK: - Inventory Item Row

struct InventoryItemRow: View {
    let item: ShopItem
    let onEquip: () -> Void
    @EnvironmentObject var appState: AppState

    private var isColorEquipped: Bool {
        guard item.category == .color else { return item.isEquipped }
        return item.name == appState.mochi.color.displayName
    }

    var body: some View {
        HStack(spacing: 12) {
            // Preview
            if item.category == .color {
                Circle()
                    .fill(colorPreview(for: item.name))
                    .frame(width: 36, height: 36)
            } else if item.category == .hat || item.category == .accessory {
                MochiAvatarView(emotion: .idle, color: .pink, equippedItems: [item], size: 36)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(backgroundEmoji)
                            .font(.title3)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.bold())
                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isColorEquipped {
                Label("Equipe", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else if item.category == .color {
                Button("Equiper") {
                    onEquip()
                }
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isColorEquipped ? Color.green.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var backgroundEmoji: String {
        switch item.name {
        case "Jardin zen": return "🪷"
        case "Bureau cosy": return "🛋️"
        case "Espace": return "🚀"
        case "Foret de bambous": return "🎋"
        default: return "🏞️"
        }
    }

    private func colorPreview(for name: String) -> Color {
        switch name {
        case "Blanc": return Color(red: 0.95, green: 0.92, blue: 0.86)
        case "Rose": return Color(red: 1.0, green: 0.8, blue: 0.85)
        case "Teal": return Color(red: 0.55, green: 0.83, blue: 0.78)
        case "Matcha": return Color(red: 0.75, green: 0.88, blue: 0.73)
        case "Bleu ciel": return Color(red: 0.75, green: 0.87, blue: 1.0)
        case "Dore": return Color(red: 1.0, green: 0.9, blue: 0.6)
        default: return Color.gray
        }
    }
}

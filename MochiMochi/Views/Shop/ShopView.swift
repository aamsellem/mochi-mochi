import SwiftUI

struct ShopView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: ItemCategory = .hat
    private let shopCategories: [ItemCategory] = [.hat, .accessory, .background]

    var body: some View {
        VStack(spacing: 0) {
            shopHeader
            Divider().opacity(0.3)

            categoryPicker
                .padding(.vertical, 8)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(filteredItems) { item in
                        ShopItemCard(
                            item: item,
                            isOwned: appState.isItemOwned(name: item.name, category: item.category),
                            isEquipped: isEquipped(item)
                        ) {
                            purchaseItem(item)
                        }
                    }
                }
                .padding()
            }

            Divider().opacity(0.3)

            HStack {
                NavigationLink(destination: InventoryView()) {
                    Label("Voir l'inventaire", systemImage: "tray.full")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(MochiTheme.primary)
                Spacer()
            }
            .padding()
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private var shopHeader: some View {
        HStack {
            Text("Boutique")
                .font(.title2.bold())
                .foregroundStyle(MochiTheme.textLight)
            Spacer()
            HStack(spacing: 4) {
                Text("🍙")
                    .font(.headline)
                Text("\(appState.gamification.riceGrains)")
                    .font(.headline.bold())
                    .foregroundStyle(.orange)
            }
        }
        .padding()
    }

    private var categoryPicker: some View {
        HStack(spacing: 6) {
            ForEach(shopCategories, id: \.self) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = category }
                } label: {
                    HStack(spacing: 4) {
                        Text(categoryIcon(category))
                            .font(.system(size: 12))
                        Text(category.displayName)
                            .font(.system(size: 12, weight: .semibold))
                    }
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

    private func categoryIcon(_ category: ItemCategory) -> String {
        switch category {
        case .color: return "🎨"
        case .hat: return "🎩"
        case .accessory: return "✨"
        case .background: return "🏞️"
        }
    }

    private var filteredItems: [ShopItem] {
        shopCatalog.filter { $0.category == selectedCategory }
    }

    private func isEquipped(_ item: ShopItem) -> Bool {
        guard item.category == .color else {
            return appState.inventory.contains { $0.name == item.name && $0.category == item.category && $0.isEquipped }
        }
        return item.name == appState.mochi.color.displayName
    }

    private func purchaseItem(_ item: ShopItem) {
        appState.purchaseItem(item)
    }
}

// MARK: - Shop Item Card

struct ShopItemCard: View {
    let item: ShopItem
    let isOwned: Bool
    let isEquipped: Bool
    let onPurchase: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 6) {
            itemPreview
            itemTitle
            Spacer(minLength: 0)
            itemStatus
            levelBadge
            purchaseButton
        }
        .frame(height: 200)
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(cardBorder)
    }

    @ViewBuilder
    private var itemPreview: some View {
        if item.category == .color {
            Circle()
                .fill(colorPreview(for: item.name))
                .frame(width: 50, height: 50)
                .shadow(color: colorPreview(for: item.name).opacity(0.4), radius: 4)
                .padding(.vertical, 15)
        } else if item.category == .hat || item.category == .accessory {
            MochiAvatarView(emotion: .idle, color: .pink, equippedItems: [item], size: 60)
                .padding(.vertical, 10)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 80)
                .overlay {
                    Text(backgroundEmoji)
                        .font(.system(size: 36))
                }
        }
    }

    private var itemTitle: some View {
        Text(item.name)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(MochiTheme.textLight)
            .lineLimit(1)
    }

    @ViewBuilder
    private var itemStatus: some View {
        if isOwned {
            if isEquipped {
                Text("Équipé")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MochiTheme.successGreen)
            } else {
                Text("Possédé")
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
            }
        } else {
            HStack(spacing: 4) {
                Text("\(item.price)")
                    .font(.system(size: 12, weight: .bold))
                Text("🍙")
                    .font(.system(size: 12))
            }
            .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var levelBadge: some View {
        if item.requiredLevel > 1 {
            Text("Niv. \(item.requiredLevel)+")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(hasLevel ? MochiTheme.textLight.opacity(0.4) : .red)
        }
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if isOwned {
            Text("Acheté")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.gray.opacity(0.08)))
        } else {
            Button {
                onPurchase()
            } label: {
                Text("Acheter")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(
                            (!canAfford || !hasLevel) ? MochiTheme.primary.opacity(0.4) : MochiTheme.primary
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canAfford || !hasLevel)
        }
    }

    private var cardBackground: some View {
        let bgColor = isOwned ? MochiTheme.successGreen.opacity(0.05) : MochiTheme.backgroundLight.opacity(0.6)
        return Rectangle().fill(bgColor)
    }

    private var cardBorder: some View {
        let strokeColor = isEquipped ? MochiTheme.successGreen.opacity(0.5) : Color.gray.opacity(0.1)
        return RoundedRectangle(cornerRadius: 10).stroke(strokeColor, lineWidth: isEquipped ? 2 : 1)
    }

    private var canAfford: Bool {
        appState.gamification.riceGrains >= item.price
    }

    private var hasLevel: Bool {
        appState.gamification.level >= item.requiredLevel
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

// MARK: - Shop Catalog

let shopCatalog: [ShopItem] = [
    // Hats
    ShopItem(name: "Beret", category: .hat, price: 20),
    ShopItem(name: "Couronne", category: .hat, price: 50, requiredLevel: 10),
    ShopItem(name: "Casquette", category: .hat, price: 15),
    ShopItem(name: "Chapeau sorcier", category: .hat, price: 40, requiredLevel: 8),
    ShopItem(name: "Bandeau ninja", category: .hat, price: 35, requiredLevel: 5),

    // Accessories
    ShopItem(name: "Lunettes", category: .accessory, price: 15),
    ShopItem(name: "Echarpe", category: .accessory, price: 20),
    ShopItem(name: "Noeud papillon", category: .accessory, price: 25),
    ShopItem(name: "Cape", category: .accessory, price: 60, requiredLevel: 15),
    ShopItem(name: "Ailes", category: .accessory, price: 100, requiredLevel: 20),

    // Backgrounds
    ShopItem(name: "Jardin zen", category: .background, price: 80, requiredLevel: 10),
    ShopItem(name: "Bureau cosy", category: .background, price: 50, requiredLevel: 5),
    ShopItem(name: "Espace", category: .background, price: 150, requiredLevel: 25),
    ShopItem(name: "Foret de bambous", category: .background, price: 100, requiredLevel: 15),
]

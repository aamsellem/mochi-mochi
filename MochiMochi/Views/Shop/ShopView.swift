import SwiftUI

struct ShopView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: ItemCategory = .color
    @State private var showEquipAlert = false
    @State private var lastPurchasedColorName: String?

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
        .alert("Couleur achetee !", isPresented: $showEquipAlert) {
            Button("Equiper maintenant") {
                if let name = lastPurchasedColorName {
                    appState.equipColor(name)
                }
            }
            Button("Plus tard", role: .cancel) {}
        } message: {
            Text("Veux-tu equiper cette couleur maintenant ?")
        }
    }

    private var shopHeader: some View {
        HStack {
            Text("Boutique")
                .font(.title2.bold())
                .foregroundStyle(MochiTheme.textLight)
            Spacer()
            Label("\(appState.gamification.riceGrains) 🍙", systemImage: "leaf.fill")
                .font(.headline)
                .foregroundStyle(.orange)
        }
        .padding()
    }

    private var categoryPicker: some View {
        Picker("Categorie", selection: $selectedCategory) {
            ForEach(ItemCategory.allCases, id: \.self) { category in
                Text(category.displayName).tag(category)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
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
        if item.category == .color {
            lastPurchasedColorName = item.name
            showEquipAlert = true
        }
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
        VStack(spacing: 8) {
            itemPreview
            itemTitle
            itemStatus
            levelBadge
            purchaseButton
        }
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
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 80)
                .overlay {
                    Text(categoryEmoji)
                        .font(.system(size: 32))
                }
        }
    }

    private var itemTitle: some View {
        Text(item.name)
            .font(.subheadline.bold())
            .lineLimit(1)
    }

    @ViewBuilder
    private var itemStatus: some View {
        if isOwned {
            if isEquipped {
                Text("Equipe")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            } else {
                Text("Possede")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: 4) {
                Text("\(item.price)")
                    .font(.caption.bold())
                Text("🍙")
                    .font(.caption)
            }
            .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var levelBadge: some View {
        if item.requiredLevel > 1 {
            let color: Color = hasLevel ? .secondary : .red
            Text("Niv. \(item.requiredLevel)+")
                .font(.caption2)
                .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if isOwned {
            Button("Achete") {}
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(true)
        } else {
            Button("Acheter") {
                onPurchase()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(!canAfford || !hasLevel)
        }
    }

    private var cardBackground: some View {
        let bgColor = isOwned ? Color.green.opacity(0.03) : Color.secondary.opacity(0.05)
        return Rectangle().fill(bgColor)
    }

    private var cardBorder: some View {
        let strokeColor = isEquipped ? Color.green.opacity(0.5) : Color.clear
        return RoundedRectangle(cornerRadius: 10).stroke(strokeColor, lineWidth: 2)
    }

    private var canAfford: Bool {
        appState.gamification.riceGrains >= item.price
    }

    private var hasLevel: Bool {
        appState.gamification.level >= item.requiredLevel
    }

    private var categoryEmoji: String {
        switch item.category {
        case .color: return "🎨"
        case .hat: return "🎩"
        case .accessory: return "👓"
        case .background: return "🏞️"
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
    // Colors (matching the level/price table)
    ShopItem(name: "Blanc", category: .color, price: 15, requiredLevel: 3),
    ShopItem(name: "Matcha", category: .color, price: 25, requiredLevel: 5),
    ShopItem(name: "Bleu ciel", category: .color, price: 35, requiredLevel: 8),
    ShopItem(name: "Dore", category: .color, price: 50, requiredLevel: 12),

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

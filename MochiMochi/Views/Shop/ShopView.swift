import SwiftUI

struct ShopView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: ItemCategory = .color

    var body: some View {
        VStack(spacing: 0) {
            // Header with rice grains balance
            shopHeader
            Divider()

            // Category filter
            categoryPicker
                .padding(.vertical, 8)

            // Items grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(filteredItems) { item in
                        ShopItemCard(item: item) {
                            purchaseItem(item)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var shopHeader: some View {
        HStack {
            Text("Boutique")
                .font(.title2.bold())
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

    private func purchaseItem(_ item: ShopItem) {
        guard appState.gamification.riceGrains >= item.price else { return }
        guard appState.gamification.level >= item.requiredLevel else { return }

        appState.gamification.riceGrains -= item.price
        // In a full implementation, mark item as owned in inventory
        appState.saveState()
    }
}

// MARK: - Shop Item Card

struct ShopItemCard: View {
    let item: ShopItem
    let onPurchase: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            // Item preview placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 80)
                .overlay {
                    Text(categoryEmoji)
                        .font(.system(size: 32))
                }

            Text(item.name)
                .font(.subheadline.bold())
                .lineLimit(1)

            HStack(spacing: 4) {
                Text("\(item.price)")
                    .font(.caption.bold())
                Text("🍙")
                    .font(.caption)
            }
            .foregroundStyle(.orange)

            if item.requiredLevel > 1 {
                Text("Niv. \(item.requiredLevel)+")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button(item.isOwned ? "Possede" : "Acheter") {
                onPurchase()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(item.isOwned || !canAfford || !hasLevel)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
}

// MARK: - Shop Catalog

let shopCatalog: [ShopItem] = [
    // Colors
    ShopItem(name: "Rose", category: .color, price: 10),
    ShopItem(name: "Matcha", category: .color, price: 10),
    ShopItem(name: "Bleu ciel", category: .color, price: 10),
    ShopItem(name: "Dore", category: .color, price: 30, requiredLevel: 5),

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

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
            Spacer()
            Text("\(allOwnedItems.count) items")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Aucun item dans cette categorie")
                .foregroundStyle(.secondary)
            Text("Visite la boutique pour debloquer des items !")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(ownedItems) { item in
                    InventoryItemRow(item: item)
                }
            }
            .padding()
        }
    }

    private var ownedItems: [ShopItem] {
        appState.mochi.equippedItems.filter { $0.category == selectedCategory && $0.isOwned }
    }

    private var allOwnedItems: [ShopItem] {
        appState.mochi.equippedItems.filter { $0.isOwned }
    }
}

// MARK: - Inventory Item Row

struct InventoryItemRow: View {
    let item: ShopItem

    var body: some View {
        HStack(spacing: 12) {
            // Preview
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(categoryEmoji)
                        .font(.title3)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.bold())
                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.isEquipped {
                Label("Equipe", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Button("Equiper") {
                    // Toggle equip in a full implementation
                }
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(item.isEquipped ? Color.green.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

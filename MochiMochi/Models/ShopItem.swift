import Foundation

// MARK: - Item Category

enum ItemCategory: String, Codable, CaseIterable {
    case color
    case hat
    case accessory
    case background

    var displayName: String {
        switch self {
        case .color: return "Couleurs"
        case .hat: return "Chapeaux"
        case .accessory: return "Accessoires"
        case .background: return "Decors"
        }
    }
}

// MARK: - Shop Item

struct ShopItem: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let category: ItemCategory
    let price: Int
    let requiredLevel: Int
    var isOwned: Bool
    var isEquipped: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: ItemCategory,
        price: Int,
        requiredLevel: Int = 1,
        isOwned: Bool = false,
        isEquipped: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.price = price
        self.requiredLevel = requiredLevel
        self.isOwned = isOwned
        self.isEquipped = isEquipped
    }

    static func == (lhs: ShopItem, rhs: ShopItem) -> Bool {
        lhs.id == rhs.id
    }
}

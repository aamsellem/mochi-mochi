import SwiftUI

// MARK: - Shop Tab Enum

private enum ShopTab: String, CaseIterable {
    case all, hat, accessory, owned

    var label: String {
        switch self {
        case .all: return "Tout"
        case .hat: return "Chapeaux"
        case .accessory: return "Accessoires"
        case .owned: return "Mes items"
        }
    }

    var icon: String {
        switch self {
        case .all: return "sparkles"
        case .hat: return "🎩"
        case .accessory: return "✨"
        case .owned: return "tray.full"
        }
    }

    var isEmoji: Bool {
        switch self {
        case .all, .owned: return false
        default: return true
        }
    }
}

// MARK: - ShopView

struct ShopView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: ShopTab = .all
    @State private var hoveredItem: String? = nil
    @State private var bounceAvatar = false

    var body: some View {
        HStack(spacing: 0) {
            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    heroBanner
                    categoryBar
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    if selectedTab == .owned {
                        ownedSection
                    } else {
                        if selectedTab == .all {
                            featuredSection
                                .padding(.bottom, 8)
                        }
                        productGrid
                    }
                }
                .padding(.bottom, 20)
            }

            // Sidebar
            shopSidebar
        }
        .background(MochiTheme.backgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [MochiTheme.accent, MochiTheme.primary.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative rice balls
            HStack(spacing: 40) {
                Text("🍙").font(.system(size: 30)).opacity(0.08)
                Text("🍙").font(.system(size: 22)).opacity(0.06).offset(y: -15)
                Text("🍙").font(.system(size: 26)).opacity(0.07).offset(y: 10)
                Spacer()
                Text("🍙").font(.system(size: 20)).opacity(0.06).offset(y: -8)
                Text("🍙").font(.system(size: 28)).opacity(0.07)
            }
            .padding(.horizontal, 20)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Boutique")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(MochiTheme.textLight)
                    Text("Habille ton Mochi !")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                }
                Spacer()
                MochiAvatarView(
                    emotion: .excited,
                    color: appState.mochi.color,
                    equippedItems: appState.mochi.equippedItems,
                    size: 90
                )
                .scaleEffect(bounceAvatar ? 1.08 : 1.0)
                .animation(.interpolatingSpring(stiffness: 300, damping: 8), value: bounceAvatar)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        bounceAvatar = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            bounceAvatar = false
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous))
        .clipped()
    }

    // MARK: - Category Bar

    private var categoryBar: some View {
        HStack(spacing: 6) {
            ForEach(ShopTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    HStack(spacing: 4) {
                        if tab.isEmoji {
                            Text(tab.icon).font(.system(size: 12))
                        } else {
                            Image(systemName: tab.icon).font(.system(size: 11))
                        }
                        Text(tab.label)
                            .font(.system(size: 12, weight: .semibold))

                        if tab == .owned {
                            let count = ownedItems.count
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(selectedTab == tab ? MochiTheme.primary : .white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(
                                        Capsule().fill(selectedTab == tab ? .white : MochiTheme.primary.opacity(0.5))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(selectedTab == tab ? MochiTheme.primary : Color.gray.opacity(0.06))
                    )
                    .foregroundStyle(selectedTab == tab ? .white : MochiTheme.textLight.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                Text("Articles vedettes")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MochiTheme.textLight)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(featuredItems) { item in
                        FeaturedCard(
                            item: item,
                            isOwned: appState.isItemOwned(name: item.name, category: item.category),
                            isEquipped: isEquipped(item),
                            onAction: { handleAction(item) }
                        )
                        .environmentObject(appState)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Product Grid

    private var productGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 14) {
            ForEach(filteredItems) { item in
                ProductCard(
                    item: item,
                    isOwned: appState.isItemOwned(name: item.name, category: item.category),
                    isEquipped: isEquipped(item),
                    isHovered: hoveredItem == item.name,
                    onAction: { handleAction(item) }
                )
                .environmentObject(appState)
                .onHover { hovered in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        hoveredItem = hovered ? item.name : nil
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Owned Section

    private var ownedSection: some View {
        VStack(spacing: 0) {
            if ownedItems.isEmpty {
                ownedEmptyState
            } else {
                ForEach(ownedCategories, id: \.self) { category in
                    let items = ownedItems.filter { $0.category == category }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Text(categoryEmoji(category))
                                    .font(.system(size: 13))
                                Text(category.displayName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(MochiTheme.textLight)
                                Text("\(items.count)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                            ForEach(items) { item in
                                ownedItemRow(item)
                            }
                        }
                    }
                }
            }
        }
    }

    private var ownedEmptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(MochiTheme.textLight.opacity(0.2))
            Text("Aucun item possede")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
            Text("Visite la boutique pour habiller ton Mochi !")
                .font(.system(size: 13))
                .foregroundStyle(MochiTheme.textLight.opacity(0.35))
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .all }
            } label: {
                Text("Voir la boutique")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(MochiTheme.primary))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity)
    }

    private func ownedItemRow(_ item: ShopItem) -> some View {
        let equipped = isEquipped(item)
        return HStack(spacing: 12) {
            // Preview
            MochiAvatarView(emotion: .idle, color: .pink, equippedItems: [item], size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MochiTheme.textLight)
                Text(item.category.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
            }

            Spacer()

            Button {
                if equipped {
                    appState.unequipItem(item)
                } else {
                    appState.equipItem(item)
                }
            } label: {
                if equipped {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("Equipe")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(MochiTheme.successGreen))
                } else {
                    Text("Equiper")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MochiTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(MochiTheme.primary, lineWidth: 1.5)
                        )
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(equipped ? MochiTheme.successGreen.opacity(0.05) : Color.clear)
    }

    // MARK: - Sidebar

    private var shopSidebar: some View {
        VStack(spacing: 16) {
            // Wallet
            VStack(spacing: 6) {
                Text("🍙")
                    .font(.system(size: 28))
                Text("\(appState.gamification.riceGrains)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                Text("Onigiri")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [MochiTheme.pastelYellow.opacity(0.4), MochiTheme.pastelYellow.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )

            // Mochi Preview
            VStack(spacing: 8) {
                Text("Apercu")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(0.5)

                MochiAvatarView(
                    emotion: .idle,
                    color: appState.mochi.color,
                    equippedItems: appState.mochi.equippedItems,
                    size: 110
                )
            }

            // Level & XP
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text("Niv. \(appState.gamification.level)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MochiTheme.textLight)
                }

                let xpNeeded = appState.gamification.xpRequiredForCurrentLevel
                let progress = appState.gamification.xpProgress

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.12))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [MochiTheme.primary.opacity(0.7), MochiTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 6)

                Text("\(appState.gamification.currentXP)/\(xpNeeded) XP")
                    .font(.system(size: 10))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.35))
            }

            // Collection Stats
            VStack(spacing: 4) {
                let totalItems = shopCatalog.count
                let ownedCount = ownedItems.count
                let equippedCount = appState.mochi.equippedItems.count

                HStack(spacing: 4) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.primary.opacity(0.6))
                    Text("Collection")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                }

                Text("\(ownedCount)/\(totalItems) items")
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                Text("\(equippedCount) equipe\(equippedCount > 1 ? "s" : "")")
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.35))
            }

            Spacer()
        }
        .padding(14)
        .frame(width: 220)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 1),
            alignment: .leading
        )
    }

    // MARK: - Data Helpers

    private var featuredItems: [ShopItem] {
        shopCatalog.filter { $0.price >= 50 || $0.requiredLevel >= 10 }
    }

    private var filteredItems: [ShopItem] {
        switch selectedTab {
        case .all:
            return shopCatalog
        case .hat:
            return shopCatalog.filter { $0.category == .hat }
        case .accessory:
            return shopCatalog.filter { $0.category == .accessory }
        case .owned:
            return []
        }
    }

    private var ownedItems: [ShopItem] {
        appState.inventory.filter { $0.isOwned }
    }

    private var ownedCategories: [ItemCategory] {
        [.hat, .accessory]
    }

    private func isEquipped(_ item: ShopItem) -> Bool {
        appState.inventory.contains { $0.name == item.name && $0.category == item.category && $0.isEquipped }
    }

    private func handleAction(_ item: ShopItem) {
        let owned = appState.isItemOwned(name: item.name, category: item.category)
        if owned {
            let equipped = isEquipped(item)
            if equipped {
                appState.unequipItem(item)
            } else {
                appState.equipItem(item)
            }
        } else {
            appState.purchaseItem(item)
        }
    }

    private func categoryEmoji(_ category: ItemCategory) -> String {
        switch category {
        case .color: return "🎨"
        case .hat: return "🎩"
        case .accessory: return "✨"
        case .background: return "🏞️"
        }
    }
}

// MARK: - Featured Card

private struct FeaturedCard: View {
    let item: ShopItem
    let isOwned: Bool
    let isEquipped: Bool
    let onAction: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Background gradient per category
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: cardGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(spacing: 14) {
                // Preview
                MochiAvatarView(emotion: .idle, color: .pink, equippedItems: [item], size: 70)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MochiTheme.textLight)
                        .lineLimit(1)
                    Text(item.category.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.5))

                    Spacer(minLength: 0)

                    if isOwned {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text(isEquipped ? "Equipe" : "Possede")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(isEquipped ? MochiTheme.successGreen : MochiTheme.textLight.opacity(0.4))
                    } else {
                        HStack(spacing: 3) {
                            Text("🍙")
                                .font(.system(size: 12))
                            Text("\(item.price)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .padding(14)
        }
        .frame(width: 240, height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        .onTapGesture { onAction() }
    }

    private var cardGradient: [Color] {
        switch item.category {
        case .hat: return [MochiTheme.pastelBlue.opacity(0.35), MochiTheme.pastelBlue.opacity(0.12)]
        case .accessory: return [MochiTheme.accent.opacity(0.4), MochiTheme.accent.opacity(0.12)]
        case .background: return [MochiTheme.pastelGreen.opacity(0.35), MochiTheme.pastelGreen.opacity(0.12)]
        case .color: return [MochiTheme.pastelYellow.opacity(0.35), MochiTheme.pastelYellow.opacity(0.12)]
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let item: ShopItem
    let isOwned: Bool
    let isEquipped: Bool
    let isHovered: Bool
    let onAction: () -> Void
    @EnvironmentObject var appState: AppState

    private var canAfford: Bool {
        appState.gamification.riceGrains >= item.price
    }

    private var hasLevel: Bool {
        appState.gamification.level >= item.requiredLevel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Preview zone (top ~55%)
            ZStack {
                Rectangle().fill(previewBackground)

                // Price tag (top right)
                if !isOwned {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 2) {
                                Text("🍙").font(.system(size: 10))
                                Text("\(item.price)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color(red: 1.0, green: 0.95, blue: 0.85))
                            )
                            .padding(8)
                        }
                        Spacer()
                    }
                }

                // Owned badge (top left)
                if isOwned {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(MochiTheme.successGreen)
                                .padding(8)
                            Spacer()
                        }
                        Spacer()
                    }
                }

                // Item preview
                MochiAvatarView(emotion: .idle, color: .pink, equippedItems: [item], size: 70)
            }
            .frame(height: 138)

            // Info zone (bottom ~45%)
            VStack(spacing: 6) {
                Text(item.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MochiTheme.textLight)
                    .lineLimit(1)

                Text(item.category.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))

                if item.requiredLevel > 1 {
                    Text("Niv. \(item.requiredLevel) requis")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(hasLevel ? MochiTheme.textLight.opacity(0.35) : .red.opacity(0.6))
                }

                Spacer(minLength: 0)

                // Action button
                actionButton
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .frame(height: 250)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isEquipped ? MochiTheme.successGreen.opacity(0.5) : Color.gray.opacity(0.1),
                    lineWidth: isEquipped ? 2 : 1
                )
        )
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.04), radius: isHovered ? 12 : 6, y: isHovered ? 6 : 3)
        .scaleEffect(isHovered ? 1.03 : 1.0)
    }

    @ViewBuilder
    private var actionButton: some View {
        if isOwned {
            if isEquipped {
                Button { onAction() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                        Text("Equipe")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(MochiTheme.successGreen))
                }
                .buttonStyle(.plain)
            } else {
                Button { onAction() } label: {
                    Text("Equiper")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MochiTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().stroke(MochiTheme.primary, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        } else if !hasLevel {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill").font(.system(size: 10))
                Text("Niv. \(item.requiredLevel) requis")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(MochiTheme.textLight.opacity(0.35))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.gray.opacity(0.08)))
        } else {
            Button { onAction() } label: {
                HStack(spacing: 4) {
                    Text("Acheter")
                        .font(.system(size: 12, weight: .semibold))
                    Text("🍙 \(item.price)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(canAfford ? MochiTheme.primary : MochiTheme.primary.opacity(0.35))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAfford)
        }
    }

    private var previewBackground: some ShapeStyle {
        switch item.category {
        case .hat: return MochiTheme.pastelBlue.opacity(0.2)
        case .accessory: return MochiTheme.accent.opacity(0.25)
        case .background: return MochiTheme.pastelGreen.opacity(0.2)
        case .color: return MochiTheme.pastelYellow.opacity(0.2)
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
]

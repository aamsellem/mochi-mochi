import SwiftUI

struct MochiCustomizeSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Personnaliser")
                    .font(.title3.bold())
                    .foregroundStyle(MochiTheme.textLight)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider().opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Preview
                    HStack {
                        Spacer()
                        MochiAvatarView(
                            emotion: appState.mochi.emotion,
                            color: appState.mochi.color,
                            equippedItems: appState.mochi.equippedItems,
                            size: 120
                        )
                        Spacer()
                    }
                    .padding(.vertical, 8)

                    // Colors
                    colorSection

                    // Hats
                    if !ownedHats.isEmpty {
                        equipSection(title: "Chapeaux", items: ownedHats)
                    }

                    // Accessories
                    if !ownedAccessories.isEmpty {
                        equipSection(title: "Accessoires", items: ownedAccessories)
                    }

                    // Empty state
                    if ownedHats.isEmpty && ownedAccessories.isEmpty {
                        VStack(spacing: 8) {
                            Text("Aucun accessoire")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                            Text("Visite la boutique pour acheter des chapeaux et accessoires !")
                                .font(.system(size: 12))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 340, height: 500)
        .background(Color.white)
    }

    // MARK: - Color Section

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Couleur")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(MochiTheme.textLight)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                ForEach(MochiColor.allCases, id: \.self) { color in
                    colorOption(color)
                }
            }
        }
    }

    private func colorOption(_ color: MochiColor) -> some View {
        let isSelected = appState.mochi.color == color
        let isUnlocked = color.isUnlocked(at: appState.gamification.level)

        return Button {
            guard isUnlocked else { return }
            appState.equipColor(color.displayName)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? colorPreview(color) : Color.gray.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(isSelected ? MochiTheme.primary : Color.clear, lineWidth: 2.5)
                        )
                        .shadow(color: isSelected ? MochiTheme.primary.opacity(0.3) : .clear, radius: 4)
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                    }
                }
                Text(color.displayName)
                    .font(.system(size: 9))
                    .foregroundStyle(isUnlocked ? MochiTheme.textLight.opacity(0.6) : MochiTheme.textLight.opacity(0.3))
                if !isUnlocked {
                    Text("Niv. \(color.requiredLevel)")
                        .font(.system(size: 8))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    private func colorPreview(_ color: MochiColor) -> Color {
        switch color {
        case .pink: return Color(hex: "FFB5C2")
        case .teal: return Color(hex: "8CD4C8")
        case .white: return Color(hex: "F2EDDE")
        case .matcha: return Color(hex: "BFE0B9")
        case .skyBlue: return Color(hex: "BFDDFF")
        case .golden: return Color(hex: "FFE699")
        }
    }

    // MARK: - Equip Section

    private func equipSection(title: String, items: [ShopItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(MochiTheme.textLight)

            ForEach(items) { item in
                equipRow(item)
            }
        }
    }

    private func equipRow(_ item: ShopItem) -> some View {
        let isEquipped = appState.mochi.equippedItems.contains { $0.name == item.name && $0.category == item.category }

        return HStack(spacing: 10) {
            MochiAvatarView(emotion: .idle, color: .pink, equippedItems: [item], size: 36)

            Text(item.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MochiTheme.textLight)

            Spacer()

            Button {
                if isEquipped {
                    appState.unequipItem(item)
                } else {
                    appState.equipItem(item)
                }
            } label: {
                Text(isEquipped ? "Retirer" : "Equiper")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isEquipped ? MochiTheme.textLight.opacity(0.6) : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(isEquipped ? Color.gray.opacity(0.1) : MochiTheme.primary)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isEquipped ? MochiTheme.primary.opacity(0.06) : Color.clear)
        )
    }

    // MARK: - Data

    private var ownedHats: [ShopItem] {
        appState.inventory.filter { $0.category == .hat && $0.isOwned }
    }

    private var ownedAccessories: [ShopItem] {
        appState.inventory.filter { $0.category == .accessory && $0.isOwned }
    }
}

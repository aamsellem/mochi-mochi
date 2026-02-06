import SwiftUI

enum AppTab: String, CaseIterable {
    case dashboard = "Tableau de bord"
    case tasks = "Tâches"
    case shop = "Boutique"
    case settings = "Réglages"

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .tasks: return "checklist"
        case .shop: return "bag"
        case .settings: return "gearshape"
        }
    }
}

struct NavigationBarView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack {
            logo
            Spacer()
            tabPills
            Spacer()
            notificationButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    // MARK: - Logo

    private var logo: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(MochiTheme.primary)
                .frame(width: 36, height: 36)
                .overlay(
                    Text("M")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )

            Text("Mochi.")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(MochiTheme.textLight)
        }
    }

    // MARK: - Tab Pills

    private var tabPills: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(MochiTheme.surfaceLight)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13))
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selectedTab == tab ? MochiTheme.primary : Color.clear)
            )
            .foregroundStyle(selectedTab == tab ? .white : MochiTheme.textLight.opacity(0.6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notification

    private var notificationButton: some View {
        Button {
        } label: {
            Circle()
                .fill(MochiTheme.surfaceLight)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
                .overlay(
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationBarView(selectedTab: .constant(.dashboard))
        .frame(width: 900)
        .background(MochiTheme.backgroundLight)
}

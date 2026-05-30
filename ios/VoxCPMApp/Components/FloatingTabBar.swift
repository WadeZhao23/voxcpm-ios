import SwiftUI

/// 浮动胶囊 TabBar（移植自 Ego：白底 Capsule，选中项 `#EFEFEF` 胶囊 + 靛蓝 tint）。
/// 这里用 SF Symbols 代替 Ego 的自定义图标资源。
struct FloatingTabBar: View {
    @Binding var selection: Int
    let items: [Item]

    struct Item: Identifiable {
        let tag: Int
        let title: String
        let icon: String   // SF Symbol 名
        var id: Int { tag }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                tabButton(for: item)
            }
        }
        .padding(4)
        .background(Capsule(style: .continuous).fill(Color.white))
        .egoCardShadow()
    }

    private func tabButton(for item: Item) -> some View {
        let isSelected = selection == item.tag
        let tint = isSelected ? AppColor.brand : Color(hex: "1A1A1A")
        return Button {
            withAnimation(.egoSpring) { selection = item.tag }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(tint)
                    .frame(height: 20)

                Text(item.title)
                    .font(.app(size: 10, weight: .semibold))
                    .foregroundColor(tint)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color(hex: "EFEFEF") : Color.clear)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

import SwiftUI

/// 统一的一级页面骨架：大标题头部 + 可滚动卡片内容（底部留出浮动 TabBar 空间）。
struct ScreenScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.app(size: 28, weight: .bold))
                        .foregroundColor(AppColor.textPrimary)
                    Text(subtitle)
                        .font(.app(size: 14))
                        .foregroundColor(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)
                .padding(.bottom, 4)

                content
            }
            .padding(.horizontal, AppSpacing.screenH)
            .padding(.bottom, AppSpacing.tabBarClearance)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

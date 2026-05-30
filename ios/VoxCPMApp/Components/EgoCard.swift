import SwiftUI

/// 白色圆角卡片容器（Ego 风格：radius 20 continuous + 轻阴影）。
struct EgoCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.cardPadding
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColor.card)
            )
            .egoCardShadow()
    }
}

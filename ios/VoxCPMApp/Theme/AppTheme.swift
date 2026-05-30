import SwiftUI

/// Ego 设计系统：圆角 / 间距 / 阴影 / 动效常量。
enum AppRadius {
    static let card: CGFloat = 20
    static let cardLarge: CGFloat = 24
    static let control: CGFloat = 16
    static let small: CGFloat = 12
}

enum AppSpacing {
    static let screenH: CGFloat = 20      // 屏幕左右边距
    static let cardPadding: CGFloat = 18
    static let sectionGap: CGFloat = 16
    static let tabBarClearance: CGFloat = 110  // 浮动 TabBar 占位留白
}

extension Animation {
    /// Ego 招牌弹簧动效。
    static var egoSpring: Animation { .spring(response: 0.32, dampingFraction: 0.86) }
}

extension View {
    /// Ego 卡片轻阴影（黑 5%）。
    func egoCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 6)
    }
}

/// Ego 按压反馈：轻微缩放 + 透明度（参照 Ego ProIntroButtonStyle）。
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

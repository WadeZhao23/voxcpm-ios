import SwiftUI

/// 靛蓝胶囊主按钮（Ego CTA 风格），带 loading 态与按压反馈。
struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                }
                Text(title)
                    .font(.app(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule(style: .continuous)
                    .fill((enabled && !isLoading) ? AppColor.brand : AppColor.brand.opacity(0.4))
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled || isLoading)
    }
}

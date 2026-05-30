import SwiftUI

/// 区块小标题
struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.app(size: 13, weight: .semibold))
            .foregroundColor(AppColor.textSecondary)
    }
}

/// 多行文本输入（Ego 风格：浅填充圆角 + OPPO 字体 + 占位符）
struct AppTextArea: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 110

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.app(size: 15))
                    .foregroundColor(AppColor.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
            }
            TextEditor(text: $text)
                .font(.app(size: 15))
                .foregroundColor(AppColor.textPrimary)
                .tint(AppColor.brand)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
        }
        .frame(minHeight: minHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(AppColor.fill)
        )
    }
}

/// 单行文本输入
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(AppColor.textTertiary))
            .font(.app(size: 15))
            .foregroundColor(AppColor.textPrimary)
            .tint(AppColor.brand)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .fill(AppColor.fill)
            )
    }
}

/// 带标题与数值的滑块（靛蓝 tint）
struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.app(size: 14)).foregroundColor(AppColor.textPrimary)
                Spacer()
                Text(String(format: format, value))
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.brand)
            }
            Slider(value: $value, in: range, step: step)
                .tint(AppColor.brand)
        }
    }
}

/// 合成结果播放条
struct PlaybackBar: View {
    @ObservedObject var player: AudioPlayback
    let data: Data?

    var body: some View {
        EgoCard(padding: 14) {
            HStack(spacing: 12) {
                Button {
                    if let data { player.play(data: data) }
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(AppColor.brand))
                }
                .buttonStyle(PressableButtonStyle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("合成结果")
                        .font(.app(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                    Text("点击重新播放")
                        .font(.app(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
            }
        }
    }
}

/// 错误提示条
struct ErrorNote: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(AppColor.red)
            Text(text)
                .font(.app(size: 13))
                .foregroundColor(AppColor.red)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(AppColor.red.opacity(0.08))
        )
    }
}

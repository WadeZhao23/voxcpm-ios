import SwiftUI

/// 带标题和数值显示的滑块。
struct Stepperized: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    init(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title): \(String(format: format, value))")
                .font(.subheadline)
            Slider(value: $value, in: range, step: step)
        }
    }
}

/// 统一的「生成语音」按钮，带 loading 态。
struct GenerateButton: View {
    let isLoading: Bool
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading { ProgressView() }
                Text(isLoading ? "合成中…" : "生成语音")
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(isLoading || disabled)
    }
}

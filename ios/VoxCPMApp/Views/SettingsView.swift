import SwiftUI

/// 配置后端地址，并测试连通性。
struct SettingsView: View {
    @AppStorage(AppConfig.serverURLKey) private var serverURL = AppConfig.defaultServerURL
    private let client = VoxCPMClient()
    @State private var status: ConnectionStatus?
    @State private var checking = false

    enum ConnectionStatus {
        case ok, fail(String)
    }

    var body: some View {
        ScreenScaffold(title: "设置", subtitle: "配置 VoxCPM 推理后端地址") {
            EgoCard {
                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel(text: "后端服务地址")
                    AppTextField(placeholder: "http://localhost:8000", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Text("模拟器用 localhost；真机请填 Mac 的局域网 IP，例如 http://192.168.1.10:8000")
                        .font(.app(size: 12))
                        .foregroundColor(AppColor.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            PrimaryButton(title: checking ? "测试中…" : "测试连接", isLoading: checking) {
                check()
            }

            if let status {
                statusRow(status)
            }

            EgoCard {
                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(text: "关于")
                    Text("基于 OpenBMB VoxCPM2 的本地语音合成。前端通过 HTTP 调用本机 / 局域网内的推理后端，模型在后端机器上运行。")
                        .font(.app(size: 13))
                        .foregroundColor(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
            }
        }
    }

    @ViewBuilder
    private func statusRow(_ status: ConnectionStatus) -> some View {
        switch status {
        case .ok:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(AppColor.green)
                Text("连接成功").font(.app(size: 14, weight: .semibold)).foregroundColor(AppColor.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous).fill(AppColor.green.opacity(0.10)))
        case .fail(let msg):
            ErrorNote(text: msg)
        }
    }

    private func check() {
        checking = true
        status = nil
        Task {
            do {
                let ok = try await client.health()
                status = ok ? .ok : .fail("服务无响应")
            } catch {
                status = .fail(error.localizedDescription)
            }
            checking = false
        }
    }
}

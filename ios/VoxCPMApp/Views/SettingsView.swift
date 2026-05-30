import SwiftUI

/// 配置后端地址，并测试连通性。
struct SettingsView: View {
    @AppStorage(AppConfig.serverURLKey) private var serverURL = AppConfig.defaultServerURL
    private let client = VoxCPMClient()
    @State private var status: String?
    @State private var checking = false

    var body: some View {
        NavigationStack {
            Form {
                Section("后端服务地址") {
                    TextField("http://localhost:8000", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Text("模拟器用 localhost；真机请填 Mac 的局域网 IP，例如 http://192.168.1.10:8000")
                        .font(.footnote).foregroundColor(.secondary)
                }
                Section {
                    Button(action: check) {
                        HStack {
                            if checking { ProgressView() }
                            Text("测试连接")
                        }
                    }
                    .disabled(checking)
                    if let status {
                        Text(status).font(.footnote)
                    }
                }
                Section("关于") {
                    Text("基于 OpenBMB VoxCPM2，前端通过 HTTP 调用本机 / 局域网内的推理后端。")
                        .font(.footnote).foregroundColor(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }

    private func check() {
        checking = true
        status = nil
        Task {
            do {
                let ok = try await client.health()
                status = ok ? "✅ 连接成功" : "⚠️ 服务无响应"
            } catch {
                status = "❌ \(error.localizedDescription)"
            }
            checking = false
        }
    }
}

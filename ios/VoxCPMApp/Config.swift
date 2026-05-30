import Foundation

/// 后端地址配置。模拟器可直接用 localhost 访问 Mac 上的后端；
/// 真机请在「设置」页改成 Mac 的局域网 IP（如 http://192.168.1.10:8000）。
enum AppConfig {
    static let serverURLKey = "serverURL"
    static let defaultServerURL = "http://localhost:8000"

    static var serverBaseURL: URL {
        let raw = UserDefaults.standard.string(forKey: serverURLKey) ?? defaultServerURL
        return URL(string: raw) ?? URL(string: defaultServerURL)!
    }
}

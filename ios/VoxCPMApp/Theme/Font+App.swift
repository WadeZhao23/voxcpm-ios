import SwiftUI

extension Font {
    /// OPPO Sans 全局字体入口（与 Ego 设计系统一致）。
    ///
    /// OPPO Sans 的 5 个字重在 ttf 里是 5 个独立 family（PostScript: `OPPOSans-R/M/B/L/H`），
    /// 不能用 `.weight()` 从单 family 派生，必须按字重直接取对应 PostScript 名。
    static func app(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design? = nil) -> Font {
        .custom(oppoSansPostScriptName(for: weight), size: size)
    }

    private static func oppoSansPostScriptName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light:
            return "OPPOSans-L"
        case .medium, .semibold:
            return "OPPOSans-M"
        case .bold:
            return "OPPOSans-B"
        case .heavy, .black:
            return "OPPOSans-H"
        default: // .regular 及未知字重
            return "OPPOSans-R"
        }
    }
}

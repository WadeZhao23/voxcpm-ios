import SwiftUI

/// Ego 设计系统语义色 token（hex 值提取自 Ego 真实工程）。
enum AppColor {
    // 品牌
    static let brand = Color(hex: "3C4FC1")          // 靛蓝主色
    static let brandSoft = Color(hex: "3C4FC1").opacity(0.10)

    // 文字
    static let textPrimary = Color(hex: "2F3337")    // 主文字
    static let textSecondary = Color(hex: "9AA09F")  // 次文字
    static let textTertiary = Color(hex: "C0C4CC")   // 占位 / 禁用

    // 背景与 surface
    static let pageBackground = Color(hex: "EFF7F3") // 薄荷页面底（Ego 招牌底色）
    static let card = Color.white                    // 卡片
    static let fill = Color(hex: "F6F6F6")           // 浅填充（输入框等）
    static let fillStrong = Color(hex: "F0F0F0")

    // 语义强调色
    static let red = Color(hex: "E85D5D")
    static let orange = Color(hex: "E88A3C")
    static let purple = Color(hex: "A88DE8")
    static let blue = Color(hex: "5B8DEF")
    static let teal = Color(hex: "22BEC5")
    static let green = Color(hex: "4BC87E")
}

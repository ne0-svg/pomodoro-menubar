import AppKit

/// 菜单栏图标入口：黑白模板图，跟随菜单栏深浅色与高亮自动反色。
enum StatusIcon {
    /// 计时状态：经典麦金塔
    static let mac: NSImage = StatusGlyph.mac
    /// 休息状态：双手叉腰的人形
    static let person: NSImage = StatusGlyph.person
}

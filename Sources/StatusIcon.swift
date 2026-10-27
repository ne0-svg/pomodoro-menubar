import AppKit

/// 菜单栏图标：8-bit 像素模板图，跟随菜单栏深浅色与高亮自动反色。
enum StatusIcon {
    /// 计时状态：经典麦金塔
    static let mac: NSImage = PixelIcon.mac
    /// 休息状态：冒热气的咖啡杯
    static let coffee: NSImage = PixelIcon.coffee
}

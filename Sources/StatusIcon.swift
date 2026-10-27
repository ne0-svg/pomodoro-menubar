import AppKit

/// 菜单栏图标：模板图，跟随菜单栏深浅色与高亮自动反色。
enum StatusIcon {
    /// 计时状态：圆环箭头 + 指针
    static let timer: NSImage = StatusGlyph.timer
    /// 休息状态：冒热气的像素咖啡杯
    static let coffee: NSImage = PixelIcon.coffee
}

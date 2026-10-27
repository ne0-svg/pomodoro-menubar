import AppKit

/// 菜单栏图标：休息态用模板像素图（跟随深浅色反色）；计时态用 emoji 🐾，不带图片。
enum StatusIcon {
    /// 休息状态：冒热气的像素咖啡杯
    static let coffee: NSImage = PixelIcon.coffee
}

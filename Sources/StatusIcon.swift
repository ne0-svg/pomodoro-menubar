import AppKit

/// 菜单栏图标：使用打包在 Resources 里的像素图（模板渲染，跟随深浅色与高亮反色）。
/// 找不到资源时退回代码里画的 PixelIcon。
enum StatusIcon {

    /// 计时状态：8-bit 麦金塔
    static let mac: NSImage = bundled("menubar-mac") ?? PixelIcon.mac

    /// 休息状态：双手叉腰的人形
    static let person: NSImage = bundled("menubar-person") ?? PixelIcon.coffee

    private static func bundled(_ name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        return image
    }
}

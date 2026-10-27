import AppKit

/// 8-bit 像素图标：16×16 字符画渲染成模板位图（每格 2×2 设备像素，2x 屏上边缘是硬的）。
enum PixelIcon {

    /// 计时状态：经典麦金塔（参考图重绘）
    static let mac = make(macArt)

    /// 休息状态：冒热气的咖啡杯
    static let coffee = make(coffeeArt)

    // MARK: - 字符画

    private static let macArt: [String] = [
        "................",
        "..############..",
        "..#..........#..",
        "..#.########.#..",
        "..#.#......#.#..",
        "..#.#.#..#.#.#..",
        "..#.#..#...#.#..",
        "..#.#.####.#.#..",
        "..#.########.#..",
        "..#..........#..",
        "..#.#....###.#..",
        "..############..",
        "...##########...",
        "...##########...",
        "................",
        "................",
    ]

    private static let coffeeArt: [String] = [
        "....#.....#.....",
        ".....#.....#....",
        "................",
        "..############..",
        "..############..",
        "..############.##",
        "..############..#",
        "..############..#",
        "..############.##",
        "...##########...",
        "....########....",
        "...##########...",
        "..############..",
        "................",
        "................",
        "................",
    ]

    // MARK: - 渲染

    private static func make(_ art: [String]) -> NSImage {
        let height = art.count
        let width = art.first?.count ?? 16
        let scale = 2

        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: width * scale,
                                   pixelsHigh: height * scale,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: CGFloat(width), height: CGFloat(height))

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.shouldAntialias = false
        NSColor.black.setFill()

        for (row, line) in art.enumerated() {
            for (col, ch) in line.enumerated() where ch == "#" {
                NSRect(x: CGFloat(col), y: CGFloat(height - 1 - row), width: 1, height: 1).fill()
            }
        }

        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: NSSize(width: CGFloat(width), height: CGFloat(height)))
        image.addRepresentation(rep)
        image.isTemplate = true
        return image
    }
}

// Draws the Tock app icon at 1024×1024 and writes it as a PNG.
// Usage: swift scripts/icon.swift out.png   (scripts/icon.sh wraps this)
import AppKit

let side = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// The plate: the standard macOS icon shape, inset from the canvas edge.
let plate = NSBezierPath(
    roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)

NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.set()
NSColor.black.setFill()
plate.fill()
NSGraphicsContext.restoreGraphicsState()

NSGradient(
    starting: NSColor(srgbRed: 0.24, green: 0.25, blue: 0.29, alpha: 1),
    ending: NSColor(srgbRed: 0.08, green: 0.085, blue: 0.11, alpha: 1))!
    .draw(in: plate, angle: -90)

// The same glyph as the menu bar: white pointer, amber click marks.
let amber = NSColor(srgbRed: 1.0, green: 0.72, blue: 0.26, alpha: 1)
let config = NSImage.SymbolConfiguration(pointSize: 400, weight: .medium)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white, amber]))
let glyph = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: nil)!
    .withSymbolConfiguration(config)!
let size = glyph.size
glyph.draw(in: NSRect(
    x: (Double(side) - size.width) / 2, y: (Double(side) - size.height) / 2,
    width: size.width, height: size.height))

NSGraphicsContext.current?.flushGraphics()
try rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))

import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = root.appendingPathComponent("Rat/Resources", isDirectory: true)
let iconsetURL = root.appendingPathComponent("build/RatIcon.iconset", isDirectory: true)
let sourceLogoURL = resourcesURL.appendingPathComponent("RatLogoSource.png")

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
try FileManager.default.removeItemIfExists(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

extension FileManager {
    func removeItemIfExists(at url: URL) throws {
        if fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
    }
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "RatIconGenerator", code: 1)
    }

    try data.write(to: url)
}

func cropRectForVisibleLogo(in image: NSImage) -> NSRect {
    guard let bitmap = bitmapByDrawingInDeviceRGB(image) else {
        return NSRect(origin: .zero, size: image.size)
    }

    var minX = bitmap.pixelsWide
    var minY = bitmap.pixelsHigh
    var maxX = 0
    var maxY = 0

    for y in 0..<bitmap.pixelsHigh {
        for x in 0..<bitmap.pixelsWide {
            guard let color = rgbaComponents(atX: x, y: y, in: bitmap) else {
                continue
            }

            let isWhiteBackground = color.red > 0.94 && color.green > 0.94 && color.blue > 0.94
            if !isWhiteBackground {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }

    guard minX <= maxX, minY <= maxY else {
        return NSRect(origin: .zero, size: image.size)
    }

    let padding = 8
    minX = max(0, minX - padding)
    minY = max(0, minY - padding)
    maxX = min(bitmap.pixelsWide - 1, maxX + padding)
    maxY = min(bitmap.pixelsHigh - 1, maxY + padding)

    let width = maxX - minX + 1
    let height = maxY - minY + 1
    let side = max(width, height)
    let squareX = max(0, min(bitmap.pixelsWide - side, minX - (side - width) / 2))
    let squareYTop = max(0, min(bitmap.pixelsHigh - side, minY - (side - height) / 2))
    let squareYBottom = bitmap.pixelsHigh - squareYTop - side

    return NSRect(x: squareX, y: squareYBottom, width: side, height: side)
}

func renderSourceLogo(_ source: NSImage, size: CGFloat, cropRect: NSRect) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    source.draw(
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: cropRect,
        operation: .sourceOver,
        fraction: 1
    )
    image.unlockFocus()
    return image
}

func imageByMakingWhiteTransparent(_ image: NSImage) -> NSImage {
    guard
        let sourceBitmap = bitmapByDrawingInDeviceRGB(image),
        let outputBitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: sourceBitmap.pixelsWide,
            pixelsHigh: sourceBitmap.pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        return image
    }

    for y in 0..<sourceBitmap.pixelsHigh {
        for x in 0..<sourceBitmap.pixelsWide {
            guard let color = rgbaComponents(atX: x, y: y, in: sourceBitmap) else {
                continue
            }

            let red = color.red
            let green = color.green
            let blue = color.blue
            let brightness = max(red, green, blue)
            let darkness = min(red, green, blue)
            let saturation = brightness - darkness
            let isWhiteBackground = darkness > 0.92 || (brightness > 0.86 && saturation < 0.045)
            let alpha: CGFloat = isWhiteBackground ? 0 : color.alpha

            setRGBA(red: red, green: green, blue: blue, alpha: alpha, atX: x, y: y, in: outputBitmap)
        }
    }

    let output = NSImage(size: NSSize(width: sourceBitmap.pixelsWide, height: sourceBitmap.pixelsHigh))
    output.addRepresentation(outputBitmap)
    return output
}

func bitmapByDrawingInDeviceRGB(_ image: NSImage) -> NSBitmapImageRep? {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width),
            pixelsHigh: Int(image.size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        return nil
    }

    bitmap.size = image.size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: NSRect(origin: .zero, size: image.size))
    NSGraphicsContext.restoreGraphicsState()

    return bitmap
}

func rgbaComponents(atX x: Int, y: Int, in bitmap: NSBitmapImageRep) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
    guard let data = bitmap.bitmapData else {
        return nil
    }

    let samplesPerPixel = bitmap.samplesPerPixel
    let offset = y * bitmap.bytesPerRow + x * samplesPerPixel
    let pixel = data.advanced(by: offset)
    let alpha: CGFloat = samplesPerPixel >= 4 ? CGFloat(pixel[3]) / 255 : 1

    return (
        red: CGFloat(pixel[0]) / 255,
        green: CGFloat(pixel[1]) / 255,
        blue: CGFloat(pixel[2]) / 255,
        alpha: alpha
    )
}

func setRGBA(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat, atX x: Int, y: Int, in bitmap: NSBitmapImageRep) {
    guard let data = bitmap.bitmapData else {
        return
    }

    let samplesPerPixel = bitmap.samplesPerPixel
    let offset = y * bitmap.bytesPerRow + x * samplesPerPixel
    let pixel = data.advanced(by: offset)
    pixel[0] = byteValue(red)
    pixel[1] = byteValue(green)
    pixel[2] = byteValue(blue)
    if samplesPerPixel >= 4 {
        pixel[3] = byteValue(alpha)
    }
}

func byteValue(_ component: CGFloat) -> UInt8 {
    UInt8(max(0, min(255, Int((component * 255).rounded()))))
}

func makeImage(size: CGFloat, transparent: Bool, template: Bool) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let scale = size / 1024

    if !transparent {
        let background = NSBezierPath(roundedRect: rect, xRadius: 220 * scale, yRadius: 220 * scale)
        NSColor(red: 0.08, green: 0.085, blue: 0.09, alpha: 1).setFill()
        background.fill()

        let glow = NSBezierPath(ovalIn: NSRect(x: 220 * scale, y: 150 * scale, width: 650 * scale, height: 650 * scale))
        NSColor(red: 0.12, green: 0.95, blue: 0.56, alpha: 0.14).setFill()
        glow.fill()
    }

    let markColor = template ? NSColor.black : NSColor(red: 0.94, green: 0.92, blue: 0.86, alpha: 1)
    let accentColor = template ? NSColor.black : NSColor(red: 0.20, green: 1.0, blue: 0.58, alpha: 1)

    let symbol = NSBezierPath()
    symbol.move(to: NSPoint(x: 310 * scale, y: 662 * scale))
    symbol.curve(to: NSPoint(x: 254 * scale, y: 760 * scale), controlPoint1: NSPoint(x: 250 * scale, y: 690 * scale), controlPoint2: NSPoint(x: 228 * scale, y: 735 * scale))
    symbol.curve(to: NSPoint(x: 382 * scale, y: 740 * scale), controlPoint1: NSPoint(x: 292 * scale, y: 804 * scale), controlPoint2: NSPoint(x: 352 * scale, y: 782 * scale))
    symbol.curve(to: NSPoint(x: 560 * scale, y: 782 * scale), controlPoint1: NSPoint(x: 432 * scale, y: 770 * scale), controlPoint2: NSPoint(x: 496 * scale, y: 790 * scale))
    symbol.curve(to: NSPoint(x: 780 * scale, y: 570 * scale), controlPoint1: NSPoint(x: 690 * scale, y: 766 * scale), controlPoint2: NSPoint(x: 768 * scale, y: 668 * scale))
    symbol.curve(to: NSPoint(x: 680 * scale, y: 384 * scale), controlPoint1: NSPoint(x: 790 * scale, y: 488 * scale), controlPoint2: NSPoint(x: 748 * scale, y: 420 * scale))
    symbol.curve(to: NSPoint(x: 468 * scale, y: 354 * scale), controlPoint1: NSPoint(x: 620 * scale, y: 348 * scale), controlPoint2: NSPoint(x: 530 * scale, y: 338 * scale))
    symbol.curve(to: NSPoint(x: 300 * scale, y: 508 * scale), controlPoint1: NSPoint(x: 380 * scale, y: 376 * scale), controlPoint2: NSPoint(x: 314 * scale, y: 432 * scale))
    symbol.curve(to: NSPoint(x: 310 * scale, y: 662 * scale), controlPoint1: NSPoint(x: 290 * scale, y: 560 * scale), controlPoint2: NSPoint(x: 292 * scale, y: 616 * scale))
    symbol.close()
    markColor.setFill()
    symbol.fill()

    let snout = NSBezierPath()
    snout.move(to: NSPoint(x: 690 * scale, y: 625 * scale))
    snout.line(to: NSPoint(x: 866 * scale, y: 590 * scale))
    snout.line(to: NSPoint(x: 702 * scale, y: 522 * scale))
    snout.curve(to: NSPoint(x: 690 * scale, y: 625 * scale), controlPoint1: NSPoint(x: 724 * scale, y: 552 * scale), controlPoint2: NSPoint(x: 724 * scale, y: 596 * scale))
    snout.close()
    markColor.setFill()
    snout.fill()

    let ear = NSBezierPath(ovalIn: NSRect(x: 284 * scale, y: 640 * scale, width: 165 * scale, height: 165 * scale))
    markColor.setFill()
    ear.fill()

    let earCut = NSBezierPath(ovalIn: NSRect(x: 328 * scale, y: 684 * scale, width: 78 * scale, height: 78 * scale))
    NSColor(red: 0.08, green: 0.085, blue: 0.09, alpha: transparent ? 0 : 1).setFill()
    earCut.fill()

    let centerLine = NSBezierPath()
    centerLine.move(to: NSPoint(x: 542 * scale, y: 724 * scale))
    centerLine.curve(to: NSPoint(x: 548 * scale, y: 402 * scale), controlPoint1: NSPoint(x: 568 * scale, y: 650 * scale), controlPoint2: NSPoint(x: 568 * scale, y: 480 * scale))
    centerLine.lineWidth = max(2, 26 * scale)
    centerLine.lineCapStyle = .round
    NSColor(red: 0.08, green: 0.085, blue: 0.09, alpha: transparent ? 0.8 : 1).setStroke()
    centerLine.stroke()

    let eye = NSBezierPath(ovalIn: NSRect(x: 676 * scale, y: 590 * scale, width: 36 * scale, height: 36 * scale))
    NSColor(red: 0.08, green: 0.085, blue: 0.09, alpha: transparent ? 0.9 : 1).setFill()
    eye.fill()

    let leftArrow = NSBezierPath()
    leftArrow.move(to: NSPoint(x: 402 * scale, y: 260 * scale))
    leftArrow.line(to: NSPoint(x: 300 * scale, y: 342 * scale))
    leftArrow.line(to: NSPoint(x: 402 * scale, y: 424 * scale))
    leftArrow.lineWidth = max(3, 42 * scale)
    leftArrow.lineJoinStyle = .round
    leftArrow.lineCapStyle = .round
    accentColor.setStroke()
    leftArrow.stroke()

    let rightArrow = NSBezierPath()
    rightArrow.move(to: NSPoint(x: 622 * scale, y: 424 * scale))
    rightArrow.line(to: NSPoint(x: 724 * scale, y: 342 * scale))
    rightArrow.line(to: NSPoint(x: 622 * scale, y: 260 * scale))
    rightArrow.lineWidth = max(3, 42 * scale)
    rightArrow.lineJoinStyle = .round
    rightArrow.lineCapStyle = .round
    accentColor.setStroke()
    rightArrow.stroke()

    image.unlockFocus()
    image.isTemplate = template
    return image
}

func makeMenuBarGlyph(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let scale = size / 64
    let color = NSColor.black

    let body = NSBezierPath(ovalIn: NSRect(x: 13 * scale, y: 13 * scale, width: 38 * scale, height: 38 * scale))
    color.setFill()
    body.fill()

    let snout = NSBezierPath()
    snout.move(to: NSPoint(x: 47 * scale, y: 36 * scale))
    snout.line(to: NSPoint(x: 61 * scale, y: 32 * scale))
    snout.line(to: NSPoint(x: 47 * scale, y: 28 * scale))
    snout.close()
    snout.fill()

    let ear = NSBezierPath(ovalIn: NSRect(x: 6 * scale, y: 39 * scale, width: 19 * scale, height: 19 * scale))
    ear.fill()

    let divider = NSBezierPath()
    divider.move(to: NSPoint(x: 31 * scale, y: 46 * scale))
    divider.curve(to: NSPoint(x: 31 * scale, y: 18 * scale), controlPoint1: NSPoint(x: 35 * scale, y: 38 * scale), controlPoint2: NSPoint(x: 35 * scale, y: 26 * scale))
    divider.lineWidth = max(1.6, 4 * scale)
    divider.lineCapStyle = .round
    NSGraphicsContext.current?.compositingOperation = .clear
    NSColor.black.setStroke()
    divider.stroke()

    let eye = NSBezierPath(ovalIn: NSRect(x: 43 * scale, y: 34 * scale, width: 5 * scale, height: 5 * scale))
    NSColor.black.setFill()
    eye.fill()
    NSGraphicsContext.current?.compositingOperation = .sourceOver

    image.unlockFocus()
    image.isTemplate = true
    return image
}

let iconSizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

if FileManager.default.fileExists(atPath: sourceLogoURL.path), let sourceLogo = NSImage(contentsOf: sourceLogoURL) {
    let cropRect = cropRectForVisibleLogo(in: sourceLogo)
    let transparentLogo = imageByMakingWhiteTransparent(sourceLogo)
    try writePNG(renderSourceLogo(transparentLogo, size: 1024, cropRect: cropRect), to: resourcesURL.appendingPathComponent("RatLogo.png"))
    try writePNG(renderSourceLogo(transparentLogo, size: 64, cropRect: cropRect), to: resourcesURL.appendingPathComponent("RatMenuBarIcon.png"))

    for (name, size) in iconSizes {
        try writePNG(renderSourceLogo(transparentLogo, size: size, cropRect: cropRect), to: iconsetURL.appendingPathComponent(name))
    }
} else {
    let appIcon1024 = makeImage(size: 1024, transparent: false, template: false)
    try writePNG(appIcon1024, to: resourcesURL.appendingPathComponent("RatLogo.png"))

    let menuIcon = makeMenuBarGlyph(size: 64)
    try writePNG(menuIcon, to: resourcesURL.appendingPathComponent("RatMenuBarIcon.png"))

    for (name, size) in iconSizes {
        try writePNG(makeImage(size: size, transparent: false, template: false), to: iconsetURL.appendingPathComponent(name))
    }
}

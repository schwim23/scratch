// Renders the Scratch app icon: concentric vinyl-groove arcs on near-black,
// interrupted by a jagged amber waveform "scratch" cutting across them.
// Usage: swift Scripts/render_icon.swift <output.png>

import AppKit
import CoreGraphics

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "icon1024.png"

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0, space: space,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("no context") }

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r / 255, g / 255, b / 255, a])!
}

let charcoal = rgb(14, 14, 16)
let amber = rgb(255, 176, 46)
let offWhite = rgb(242, 239, 234)

// Background
ctx.setFillColor(charcoal)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Vinyl grooves: tight concentric rings, brightness varying in bands the way
// track separations read on a record.
let center = CGPoint(x: 512, y: 512)
var radius: CGFloat = 96
var ring = 0
while radius < 780 {
    let band = sin(Double(ring) * 0.55)
    let alpha = 0.16 + 0.18 * CGFloat(abs(band))
    ctx.setStrokeColor(rgb(140, 140, 150, alpha))
    ctx.setLineWidth(7)
    ctx.strokeEllipse(in: CGRect(
        x: center.x - radius, y: center.y - radius,
        width: radius * 2, height: radius * 2
    ))
    radius += 26
    ring += 1
}

// Label dot in the middle, like a record's center hole area.
ctx.setFillColor(charcoal)
ctx.fillEllipse(in: CGRect(x: 512 - 84, y: 512 - 84, width: 168, height: 168))
ctx.setStrokeColor(rgb(140, 140, 150, 0.5))
ctx.setLineWidth(8)
ctx.strokeEllipse(in: CGRect(x: 512 - 84, y: 512 - 84, width: 168, height: 168))
ctx.setFillColor(offWhite)
ctx.fillEllipse(in: CGRect(x: 512 - 17, y: 512 - 17, width: 34, height: 34))

// Clear a horizontal band so the waveform reads as a scratch through the grooves.
ctx.setFillColor(charcoal)
ctx.fill(CGRect(x: 0, y: 512 - 128, width: size, height: 256))

// The amber waveform scratch: deterministic speech-like bar heights.
let barCount = 23
let span: CGFloat = 832
let startX: CGFloat = (1024 - span) / 2
let slot = span / CGFloat(barCount)
let barWidth: CGFloat = slot * 0.46
ctx.setFillColor(amber)
for i in 0..<barCount {
    let t = Double(i)
    let envelope = 0.55 + 0.45 * sin(t / Double(barCount - 1) * .pi)
    let jitter = abs(sin(t * 2.7) * 0.6 + sin(t * 1.3 + 0.8) * 0.4)
    let h = max(0.10, envelope * (0.18 + 0.82 * jitter)) * 216
    let x = startX + CGFloat(i) * slot + (slot - barWidth) / 2
    let rect = CGRect(x: x, y: 512 - CGFloat(h), width: barWidth, height: CGFloat(h) * 2)
    let path = CGPath(roundedRect: rect, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil)
    ctx.addPath(path)
    ctx.fillPath()
}

guard let image = ctx.makeImage() else { fatalError("no image") }
let rep = NSBitmapImageRep(cgImage: image)
guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("no png") }
try! data.write(to: URL(fileURLWithPath: outputPath))
print("wrote \(outputPath)")

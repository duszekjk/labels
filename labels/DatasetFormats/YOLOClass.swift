import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
struct YOLOClass: Codable, Identifiable, Hashable {
    var id: String { name }
    var name: String
    var color: PlatformColor
    var occurrenceCount: Int
    private enum CodingKeys: String, CodingKey {
        case name, color, occurrenceCount
    }
    init(name: String, color: PlatformColor, occurrenceCount: Int) {
        self.name = name
        self.color = color
        self.occurrenceCount = occurrenceCount
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        occurrenceCount = try container.decode(Int.self, forKey: .occurrenceCount)
        let colorHex = try container.decode(String.self, forKey: .color)
        self.color = PlatformColor(hex: colorHex) ?? .black 
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(occurrenceCount, forKey: .occurrenceCount)
        try container.encode(color.toHex(), forKey: .color)
    }
}
#if os(iOS)
typealias PlatformColor = UIColor
#elseif os(macOS)
typealias PlatformColor = NSColor
#endif
extension PlatformColor {
    func toHex() -> String {
        #if os(iOS)
        guard let components = cgColor.components else { return "#000000" }
        #elseif os(macOS)
        guard let components = usingColorSpace(.deviceRGB)?.cgColor.components else { return "#000000" }
        #endif
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        guard let hexNumber = UInt32(hexSanitized, radix: 16) else { return nil }
        let r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
        let g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
        let b = CGFloat(hexNumber & 0x0000FF) / 255
        #if os(iOS)
        self.init(red: r, green: g, blue: b, alpha: 1.0)
        #elseif os(macOS)
        self.init(red: r, green: g, blue: b, alpha: 1.0)
        #endif
    }
}
extension Color {
    init(platformColor: PlatformColor) {
        #if os(iOS)
        self.init(uiColor:platformColor)
        #elseif os(macOS)
        self.init(nsColor:platformColor)
        #endif
    }
}

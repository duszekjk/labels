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


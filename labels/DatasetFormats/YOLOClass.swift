import SwiftUI

struct YOLOClass: Codable, Identifiable {
    var id: String { name } // Use the name as a unique identifier
    let name: String
    let color: Color
    var occurrenceCount: Int
    
    // Custom encoding and decoding for the `Color` property
    private enum CodingKeys: String, CodingKey {
        case name, color, occurrenceCount
    }
    
    init(name: String, color: Color, occurrenceCount: Int) {
        self.name = name
        self.color = color
        self.occurrenceCount = occurrenceCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let colorData = try container.decode(Data.self, forKey: .color)
        color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? Color ?? .blue
        occurrenceCount = try container.decode(Int.self, forKey: .occurrenceCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .color)
        try container.encode(occurrenceCount, forKey: .occurrenceCount)
    }
}

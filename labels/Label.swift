
import SwiftUI
struct ClassLabel: Codable, Identifiable {
    var id: UUID = UUID()
    var imageName: String
    var className: String
    var box: CGRect 
    var color: Color
    var selected: Bool = false
    private enum CodingKeys: String, CodingKey {
        case id, imageName, className, box, color
    }
    init(imageName: String, className: String, box: CGRect, color: Color) {
        self.imageName = imageName
        self.className = className
        self.box = box
        self.color = color
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(className, forKey: .className)
        let rectDict: [String: CGFloat] = [
            "x": box.origin.x,
            "y": box.origin.y,
            "width": box.size.width,
            "height": box.size.height
        ]
        try container.encode(rectDict, forKey: .box)
        let colorComponents = color.rgbaComponents
        try container.encode(colorComponents, forKey: .color)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        imageName = try container.decode(String.self, forKey: .imageName)
        className = try container.decode(String.self, forKey: .className)
        let rectDict = try container.decode([String: CGFloat].self, forKey: .box)
        box = CGRect(
            x: rectDict["x"] ?? 0,
            y: rectDict["y"] ?? 0,
            width: rectDict["width"] ?? 0,
            height: rectDict["height"] ?? 0
        )
        let colorComponents = try container.decode([CGFloat].self, forKey: .color)
        color = Color(rgba: colorComponents)
    }
}
extension Color {
    var rgbaComponents: [CGFloat] {
        let uiColor = PlatformColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha]
    }
    init(rgba components: [CGFloat]) {
        self = Color(
            .sRGB,
            red: Double(components[0]),
            green: Double(components[1]),
            blue: Double(components[2]),
            opacity: Double(components[3])
        )
    }
}

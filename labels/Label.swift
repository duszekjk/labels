import SwiftUI

struct Label: Codable, Identifiable {
    var id: UUID = UUID()
    var imageName: String
    var className: String
    var box: CGRect // Rectangle coordinates for the bounding box
    var color: Color
    
    private enum CodingKeys: String, CodingKey {
        case id, imageName, className, box, color
    }

    init(imageName: String, className: String, box: CGRect, color: Color) {
        self.imageName = imageName
        self.className = className
        self.box = box
        self.color = color
    }
}

import Foundation

enum DatasetType: String, Codable {
    case classification
    case boundingBox
    case instanceSegmentation
    case semanticSegmentation
}

struct LabelStorageFormat: Codable, Identifiable {
    var id: String { name }
    let name: String
    let description: String
}

// Predefined label storage formats
let labelStorageFormats: [LabelStorageFormat] = [
    LabelStorageFormat(name: "COCO JSON", description: "Standard format for object detection and instance segmentation."),
    LabelStorageFormat(name: "Pascal VOC JSON", description: "Derived from Pascal VOC XML annotations, supports bounding boxes."),
    LabelStorageFormat(name: "YOLO JSON", description: "Simplified bounding box format for YOLO models."),
    LabelStorageFormat(name: "LabelMe JSON", description: "Polygonal annotation format for LabelMe."),
    LabelStorageFormat(name: "Pascal VOC CSV", description: "CSV format for Pascal VOC bounding box annotations."),
    LabelStorageFormat(name: "YOLO CSV", description: "CSV format optimized for YOLO models."),
    LabelStorageFormat(name: "Custom CSV (Predefined Columns)", description: "Generic CSV format with predefined column headers."),
    LabelStorageFormat(name: "Class Subfolders", description: "Each class has its own folder with labeled images."),
    LabelStorageFormat(name: "Per-Image JSON", description: "Annotations are stored in individual JSON files per image."),
    LabelStorageFormat(name: "Per-Image CSV", description: "Annotations are stored in individual CSV files per image."),
    LabelStorageFormat(name: "Single JSON File", description: "All dataset annotations are stored in one JSON file."),
    LabelStorageFormat(name: "Single CSV File", description: "All dataset annotations are stored in one CSV file."),
    LabelStorageFormat(name: "SQLite Database", description: "Annotations are stored in a local SQLite database.")
]

// Project settings structure
struct ProjectSettings: Codable {
    var name: String
    var description: String
    var icon: String? // Path to icon file
    var hashtags: [String]
    var datasetType: DatasetType
    var labelStorage: String // Use format name for clarity
    var creationDate: Date
    var lastModifiedDate: Date
}

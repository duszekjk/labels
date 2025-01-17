
import Foundation
enum DatasetType: String, Codable {
    case classification
    case boundingBox
    case instanceSegmentation
    case semanticSegmentation
    case none
}
struct LabelStorageFormat: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let description: String
    let supportedDatasetTypes: [DatasetType]
}
let labelStorageFormats: [LabelStorageFormat] = [
    LabelStorageFormat(
        name: "COCO JSON",
        description: "Standard format for object detection and instance segmentation.",
        supportedDatasetTypes: [.boundingBox, .instanceSegmentation]
    ),
    LabelStorageFormat(
        name: "Pascal VOC JSON",
        description: "Derived from Pascal VOC XML annotations, supports bounding boxes.",
        supportedDatasetTypes: [.boundingBox]
    ),
    LabelStorageFormat(
        name: "YOLO JSON",
        description: "Simplified bounding box format for YOLO models.",
        supportedDatasetTypes: [.boundingBox]
    ),
    LabelStorageFormat(
        name: "YOLO CSV",
        description: "CSV format optimized for YOLO models.",
        supportedDatasetTypes: [.boundingBox]
    ),
    LabelStorageFormat(
        name: "LabelMe JSON",
        description: "Polygonal annotation format for LabelMe.",
        supportedDatasetTypes: [.instanceSegmentation]
    ),
    LabelStorageFormat(
        name: "SQLite Database",
        description: "Annotations are stored in a local SQLite database.",
        supportedDatasetTypes: [.classification, .boundingBox, .instanceSegmentation, .semanticSegmentation]
    ),
    LabelStorageFormat(
        name: "CoreML JSON",
        description: "Format used for Apple CoreML models, supporting bounding box annotations.",
        supportedDatasetTypes: [.boundingBox]
    )
]

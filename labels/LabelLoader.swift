//
//  YOLOAnnotation.swift
//  labels
//
//  Created by Jacek Kałużny on 13/01/2025.
//


/// Load labels in the specified format.
func loadLabelsFromFormat(
    labelStorage: String,
    filePath: URL,
    imageName: String
) -> [ClassLabel] {
    switch labelStorage {
    case "COCO JSON":
        return loadFromCOCOJSON(filePath: filePath, imageName: imageName)
    case "Pascal VOC JSON":
        return loadFromPascalVOCJSON(filePath: filePath, imageName: imageName)
    case "YOLO JSON":
        return loadFromYOLOJSON(filePath: filePath, imageName: imageName)
    case "LabelMe JSON":
        return loadFromLabelMeJSON(filePath: filePath, imageName: imageName)
    case "SQLite Database":
        return loadFromSQLiteDatabase(filePath: filePath, imageName: imageName)
    default:
        print("❌ Unsupported label storage format: \(labelStorage)")
        return []
    }
}

/// Load labels from YOLO JSON format.
private func loadFromYOLOJSON(filePath: URL, imageName: String) -> [ClassLabel] {
    struct YOLOAnnotation: Codable {
        let className: String
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
    
    let yoloFileURL = filePath.appendingPathComponent("\(imageName).json")
    
    do {
        let data = try Data(contentsOf: yoloFileURL)
        let yoloAnnotations = try JSONDecoder().decode([YOLOAnnotation].self, from: data)
        
        // Convert YOLO annotations to `ClassLabel`
        return yoloAnnotations.map { annotation in
            let originX = annotation.x - annotation.width / 2
            let originY = annotation.y - annotation.height / 2
            let box = CGRect(x: originX, y: originY, width: annotation.width, height: annotation.height)
            return ClassLabel(imageName: imageName, className: annotation.className, box: box, color: .blue) // Assign default or dynamic color
        }
    } catch {
        print("❌ Failed to load YOLO JSON: \(error)")
        return []
    }
}

/// Example: Load labels from COCO JSON format.
private func loadFromCOCOJSON(filePath: URL, imageName: String) -> [ClassLabel] {
    // Implementation for loading COCO JSON
    return []
}

/// Example: Load labels from Pascal VOC JSON format.
private func loadFromPascalVOCJSON(filePath: URL, imageName: String) -> [ClassLabel] {
    // Implementation for loading Pascal VOC JSON
    return []
}

/// Example: Load labels from LabelMe JSON format.
private func loadFromLabelMeJSON(filePath: URL, imageName: String) -> [ClassLabel] {
    // Implementation for loading LabelMe JSON
    return []
}

/// Example: Load labels from SQLite database.
private func loadFromSQLiteDatabase(filePath: URL, imageName: String) -> [ClassLabel] {
    // Implementation for loading from SQLite database
    return []
}

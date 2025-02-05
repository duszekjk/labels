
import Foundation
import SwiftUI
func saveLabelsInFormat(
    labelStorage: String,
    filePath: URL,
    labelFileName: String, 
    imageName: String, 
    labels: [ClassLabel],
    classes: inout [YOLOClass]
) {
    switch labelStorage {
    case "COCO JSON":
        saveAsCOCOJSON(filePath: filePath, imageName: imageName, labelFileName: labelFileName, labels: labels, classes: &classes)
    case "Pascal VOC JSON":
        saveAsPascalVOCJSON(filePath: filePath, labelFileName: labelFileName, labels: labels, classes: &classes)
    case "YOLO JSON":
        saveAsYOLOJSON(filePath: filePath, labelFileName: labelFileName, labels: labels, classes: &classes)
    case "YOLO CSV":
        saveAsYOLOCSV(filePath: filePath, labelFileName: labelFileName, imageName: imageName, labels: labels, classes: &classes)
    case "LabelMe JSON":
        saveAsLabelMeJSON(filePath: filePath, labelFileName: labelFileName, labels: labels, classes: &classes)
    case "SQLite Database":
        saveToSQLiteDatabase(filePath: filePath, labelFileName: labelFileName, labels: labels, classes: &classes)
    case "CoreML JSON":
        let coreMLFilePath = filePath.appendingPathComponent("coreml_annotations.json")
        saveCoreMLJSON(filePath: coreMLFilePath, imageName: imageName, labels: labels, classes: &classes)
    default:
        print("❌ Unsupported label storage format: \(labelStorage)")
    }
}
func saveAsYOLOJSON(filePath: URL, labelFileName: String, labels: [ClassLabel], classes: inout [YOLOClass]) {
    struct YOLOAnnotation: Codable {
        let className: String
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
    sortClassesByName(&classes)
    let yoloAnnotations = labels.map { label -> YOLOAnnotation in
        let xCenter = label.box.origin.x + label.box.width / 2
        let yCenter = label.box.origin.y + label.box.height / 2
        return YOLOAnnotation(
            className: label.className,
            x: xCenter,
            y: yCenter,
            width: label.box.width,
            height: label.box.height
        )
    }
    do {
        let data = try JSONEncoder().encode(yoloAnnotations)
        let yoloFileURL = filePath.appendingPathComponent(labelFileName) 
        try data.write(to: yoloFileURL, options: .atomic)
        print("✅S YOLO JSON saved successfully to \(labelFileName).")
    } catch {
        print("❌S Failed to save YOLO JSON: \(error)")
    }
}
func saveAsYOLOCSV(filePath: URL, labelFileName: String, imageName: String, labels: [ClassLabel], classes: inout [YOLOClass]) {
    let labelFileURL = filePath.appendingPathComponent(labelFileName)
    sortClassesByName(&classes)
    guard let image = UIImage(contentsOfFile: filePath.appendingPathComponent(imageName).path) else {
        print("❌S Failed to load image for dimensions: \(imageName)")
        return
    }
    let imageWidth = Double(image.size.width)
    let imageHeight = Double(image.size.height)
    var lines: [String] = []
    for label in labels {
        let boxCenterX = label.box.origin.x + label.box.width / 2
        let boxCenterY = label.box.origin.y + label.box.height / 2
        let normalizedX = boxCenterX / imageWidth
        let normalizedY = boxCenterY / imageHeight
        let normalizedWidth = label.box.width / imageWidth
        let normalizedHeight = label.box.height / imageHeight
        guard normalizedX >= 0, normalizedX <= 1,
              normalizedY >= 0, normalizedY <= 1,
              normalizedWidth >= 0, normalizedWidth <= 1,
              normalizedHeight >= 0, normalizedHeight <= 1 else {
            print("❌S Invalid box coordinates: \(label.box)")
            continue
        }
        let classIndex = classes.firstIndex { $0.name == label.className } ?? classes.count
        let line = "\(classIndex) \(String(format: "%.6f", normalizedX)) \(String(format: "%.6f", normalizedY)) \(String(format: "%.6f", normalizedWidth)) \(String(format: "%.6f", normalizedHeight))"
        lines.append(line)
    }
    do {
        let content = lines.joined(separator: "\n")
        try content.write(to: labelFileURL, atomically: true, encoding: .utf8)
        print("✅S YOLO CSV saved successfully to \(labelFileURL.path).")
    } catch {
        print("❌S Failed to save YOLO CSV: \(error)")
    }
}
private func saveAsCOCOJSON(filePath: URL, imageName: String, labelFileName: String, labels: [ClassLabel], classes: inout [YOLOClass]) {
    sortClassesByName(&classes)
    let labelFileURL = filePath.appendingPathComponent(labelFileName)
    var annotations: [String: [ClassLabel]] = [:]
    if let data = try? Data(contentsOf: labelFileURL),
       let decodedAnnotations = try? JSONDecoder().decode([String: [ClassLabel]].self, from: data) {
        annotations = decodedAnnotations
    }
    annotations[imageName] = labels
    do {
        let data = try JSONEncoder().encode(annotations)
        try data.write(to: labelFileURL, options: .atomic)
        print("✅ Labels saved successfully in COCO JSON format.")
    } catch {
        print("❌ Failed to save labels in COCO JSON format: \(error)")
    }
}
private func saveAsPascalVOCJSON(filePath: URL, labelFileName: String, labels: [ClassLabel], classes: inout [YOLOClass]) {
    sortClassesByName(&classes)
}
private func saveAsLabelMeJSON(filePath: URL, labelFileName: String, labels: [ClassLabel], classes: inout [YOLOClass]) {
    sortClassesByName(&classes)
}
private func saveToSQLiteDatabase(filePath: URL, labelFileName: String, labels: [ClassLabel], classes: inout [YOLOClass]) {
    sortClassesByName(&classes)
}
func saveCoreMLJSON(
    filePath: URL,
    imageName: String,
    labels: [ClassLabel],
    classes: inout [YOLOClass]
) {
    sortClassesByName(&classes)
    var allAnnotations = (try? JSONDecoder().decode([CoreMLAnnotation].self, from: Data(contentsOf: filePath))) ?? []
    let newAnnotations = labels.map { label in
        CoreMLAnnotation.Annotation(
            coordinates: CoreMLAnnotation.Coordinates(
                height: label.box.height,
                width: label.box.width,
                x: label.box.midX,
                y: label.box.midY
            ),
            label: label.className
        )
    }
    if let index = allAnnotations.firstIndex(where: { $0.image == imageName }) {
        allAnnotations[index].annotations = newAnnotations
    } else {
        let newAnnotation = CoreMLAnnotation(annotations: newAnnotations, image: imageName)
        allAnnotations.append(newAnnotation)
    }
    do {
        let data = try JSONEncoder().encode(allAnnotations)
        try data.write(to: filePath, options: .atomic)
    } catch {
        print("❌ Failed to save CoreML JSON: \(error)")
    }
}







func sortClassesByName(_ classes: inout [YOLOClass]) {
    classes.sort { $0.name < $1.name }
}


import SwiftUI
import Foundation
func loadLabelsFromFormat(
    labelStorage: String,
    filePath: URL,
    imageName: String,
    classes: inout [YOLOClass]
) -> (labels: [ClassLabel], labelFileName: String) {
    switch labelStorage {
    case "COCO JSON":
        print("Selected case: COCO JSON")
        return loadFromCOCOJSON(filePath: filePath, imageName: imageName, classes: &classes)
    case "Pascal VOC JSON":
        print("Selected case: Pascal VOC JSON")
        return loadFromPascalVOCJSON(filePath: filePath, imageName: imageName, classes: &classes)
    case "YOLO JSON":
        print("Selected case: YOLO JSON")
        return loadFromYOLOJSON(filePath: filePath, imageName: imageName, classes: &classes)
    case "YOLO CSV":
        print("Selected case: YOLO CSV")
        return loadFromYOLOCSV(filePath: filePath, imageName: imageName, classes: &classes)
    case "LabelMe JSON":
        print("Selected case: LabelMe JSON")
        return loadFromLabelMeJSON(filePath: filePath, imageName: imageName, classes: &classes)
    case "SQLite Database":
        print("Selected case: SQLite Database")
        return loadFromSQLiteDatabase(filePath: filePath, imageName: imageName, classes: &classes)
    case "CoreML JSON":
        print("Selected case: CoreML JSON")
        let coreMLFilePath = filePath.appendingPathComponent("coreml_annotations.json")
        let labels = loadCoreMLJSON(filePath: coreMLFilePath, imageName: imageName, classes: &classes)
        return (labels, "coreml_annotations.json")
    default:
        print("❌ Unsupported label storage format: \(labelStorage)")
        let defaultLabelFileName = imageName.replacingOccurrences(of: ".\(imageName.split(separator: ".").last ?? "")", with: ".json")
        return ([], defaultLabelFileName)
    }
}
func loadFromYOLOJSON(filePath: URL, imageName: String, classes: inout [YOLOClass]) -> (labels: [ClassLabel], labelFileName: String) {
    struct YOLOAnnotation: Codable {
        let className: String
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
    sortClassesByName(&classes)
    for index in classes.indices {
        classes[index].occurrenceCount = 0
    }
    let possibleExtensions = ["json", "txt"]
    var labelFileName: String?
    for ext in possibleExtensions {
        let potentialURL = filePath.appendingPathComponent("\(imageName).\(ext)")
        if FileManager.default.fileExists(atPath: potentialURL.path) {
            labelFileName = "\(imageName).\(ext)"
            break
        }
    }
    if labelFileName == nil {
        labelFileName = imageName.replacingOccurrences(of: ".\(imageName.split(separator: ".").last ?? "")", with: ".json")
    }
    let yoloFileURL = filePath.appendingPathComponent(labelFileName!)
    do {
        let data = try Data(contentsOf: yoloFileURL)
        let yoloAnnotations = try JSONDecoder().decode([YOLOAnnotation].self, from: data)
        var loadedLabels: [ClassLabel] = []
        for annotation in yoloAnnotations {
            let originX = annotation.x - annotation.width / 2
            let originY = annotation.y - annotation.height / 2
            let box = CGRect(x: originX, y: originY, width: annotation.width, height: annotation.height)
            if let existingClassIndex = classes.firstIndex(where: { $0.name == annotation.className }) {
                classes[existingClassIndex].occurrenceCount += 1
                let label = ClassLabel(imageName: imageName, className: annotation.className, box: box, color: Color(platformColor: classes[existingClassIndex].color))
                loadedLabels.append(label)
            } else {
                let newClassColor = Color.random
                let newClass = YOLOClass(name: annotation.className, color: PlatformColor(newClassColor), occurrenceCount: 1)
                classes.append(newClass)
                let label = ClassLabel(imageName: imageName, className: annotation.className, box: box, color: newClassColor)
                loadedLabels.append(label)
            }
        }
        return (loadedLabels, labelFileName!)
    } catch {
        print("❌L Failed to load YOLO JSON: \(error)")
        return ([], labelFileName!)
    }
}
private func loadFromYOLOCSV(filePath: URL, imageName: String, classes: inout [YOLOClass]) -> (labels: [ClassLabel], labelFileName: String) {
    let possibleExtensions = ["txt", "csv","TXT", "CSV"]
    let imageExtensions = ["jpg", "jpeg", "png", "tiff", "heic", "JPG", "JPEG", "PNG", "TIFF", "HEIC"]
    var annotationURLs: [URL] = []
    sortClassesByName(&classes)
    for annExt in possibleExtensions {
        annotationURLs.append(filePath.appendingPathComponent("\(imageName).\(annExt)"))
    }
    for imgExt in imageExtensions {
        for annExt in possibleExtensions {
            let baseName = imageName.replacingOccurrences(of: ".\(imgExt)", with: "")
            let annotationURL: URL
            do {
                annotationURL = filePath.appendingPathComponent("\(baseName).\(annExt)")
            } catch {
                print("❌L Failed to construct URL: \(error)")
                continue
            }
            annotationURLs.append(annotationURL)
        }
    }
    for imgExt in imageExtensions {
        for annExt in possibleExtensions {
            let baseName = imageName.replacingOccurrences(of: ".\(imgExt)", with: ".\(annExt)")
            if(imageName != baseName)
            {
                annotationURLs.append(filePath.appendingPathComponent("\(baseName)"))
            }
        }
    }
    let labelFileURL = annotationURLs.first(where: { FileManager.default.fileExists(atPath: $0.path) })
    let labelFileName = labelFileURL?.lastPathComponent ?? imageName.replacingOccurrences(of: ".\(imageName.split(separator: ".").last ?? "")", with: ".csv")
    do {
        guard let annotationFileURL = labelFileURL else {
            print("⚠️L No existing annotation file found for \(imageName). Using default \(labelFileName).")
            return ([], labelFileName)
        }
        let content = try String(contentsOf: annotationFileURL)
        let lines = content.split(separator: "\n")
        for index in classes.indices {
            classes[index].occurrenceCount = 0
        }
        var loadedLabels: [ClassLabel] = []
        let fullPath = filePath.appendingPathComponent(imageName).path
        if FileManager.default.fileExists(atPath: fullPath) {
            print("✅L File exists at path: \(fullPath)")
        } else {
            print("❌L Image does not exist at path: \(fullPath)")
            print("❌L Failed to load YOLO CSV")
            return ([], labelFileName)
        }
        guard let image = UIImage(contentsOfFile: fullPath) else {
            print("❌L Failed to load image for dimensions: \(imageName)")
            return ([], labelFileName)
        }
        let imageWidth = Double(image.size.width)
        let imageHeight = Double(image.size.height)
        for line in lines {
            let components = line.split(separator: " ")
            guard components.count == 5 else {
                print("❌L Invalid YOLO CSV format in line: \(line)")
                continue
            }
            guard let classIndex = Int(components[0]),
                  let centerX = Double(components[1]),
                  let centerY = Double(components[2]),
                  let width = Double(components[3]),
                  let height = Double(components[4]) else {
                print("❌L Failed to parse line: \(line)")
                continue
            }
            let absWidth = width * imageWidth
            let absHeight = height * imageHeight
            let absX = (centerX * imageWidth) - absWidth / 2
            let absY = (centerY * imageHeight) - absHeight / 2
            let box = CGRect(x: absX, y: absY, width: absWidth, height: absHeight)
            let className: String
            let classColor: Color
            if classIndex < classes.count {
                className = classes[classIndex].name
                classColor = Color(platformColor: classes[classIndex].color)
                classes[classIndex].occurrenceCount += 1
            } else {
                className = "\(classIndex)"
                classColor = Color.random
                let newClass = YOLOClass(name: className, color: PlatformColor(classColor), occurrenceCount: 1)
                classes.append(newClass)
            }
            let label = ClassLabel(imageName: imageName, className: className, box: box, color: classColor)
            loadedLabels.append(label)
        }
        return (loadedLabels, labelFileName)
    } catch {
        for index in classes.indices {
            classes[index].occurrenceCount = 0
        }
        print("❌L Failed to load YOLO CSV: \(error)")
        return ([], labelFileName)
    }
}
func loadFromCOCOJSON(filePath: URL, imageName: String, classes: inout [YOLOClass]) -> (labels: [ClassLabel], labelFileName: String) {
    let possibleExtensions = ["json"]
    var labelFileName: String?
    sortClassesByName(&classes)
    for ext in possibleExtensions {
        let potentialURL = filePath.appendingPathComponent("\(imageName).\(ext)")
        if FileManager.default.fileExists(atPath: potentialURL.path) {
            labelFileName = "\(imageName).\(ext)"
            break
        }
    }
    if labelFileName == nil {
        labelFileName = imageName.replacingOccurrences(of: ".\(imageName.split(separator: ".").last ?? "")", with: ".json")
    }
    return ([], labelFileName!)
}
func loadFromPascalVOCJSON(filePath: URL, imageName: String, classes: inout [YOLOClass]) -> (labels: [ClassLabel], labelFileName: String) {
    let possibleExtensions = ["json", "xml"]
    var labelFileName: String?
    sortClassesByName(&classes)
    for ext in possibleExtensions {
        let potentialURL = filePath.appendingPathComponent("\(imageName).\(ext)")
        if FileManager.default.fileExists(atPath: potentialURL.path) {
            labelFileName = "\(imageName).\(ext)"
            break
        }
    }
    if labelFileName == nil {
        labelFileName = imageName.replacingOccurrences(of: ".\(imageName.split(separator: ".").last ?? "")", with: ".xml")
    }
    return ([], labelFileName!)
}
func loadFromLabelMeJSON(filePath: URL, imageName: String, classes: inout [YOLOClass]) -> (labels: [ClassLabel], labelFileName: String) {
    let possibleExtensions = ["json"]
    var labelFileName: String?
    sortClassesByName(&classes)
    for ext in possibleExtensions {
        let potentialURL = filePath.appendingPathComponent("\(imageName).\(ext)")
        if FileManager.default.fileExists(atPath: potentialURL.path) {
            labelFileName = "\(imageName).\(ext)"
            break
        }
    }
    if labelFileName == nil {
        labelFileName = imageName.replacingOccurrences(of: ".\(imageName.split(separator: ".").last ?? "")", with: ".json")
    }
    return ([], labelFileName!)
}
func loadFromSQLiteDatabase(filePath: URL, imageName: String, classes: inout [YOLOClass]) -> (labels: [ClassLabel], labelFileName: String) {
    let labelFileName = "annotations.sqlite"
    sortClassesByName(&classes)
    return ([], labelFileName)
}
func loadCoreMLJSON(
    filePath: URL,
    imageName: String,
    classes: inout [YOLOClass]
) -> [ClassLabel] {
    sortClassesByName(&classes)
    let allAnnotations = (try? JSONDecoder().decode([CoreMLAnnotation].self, from: Data(contentsOf: filePath))) ?? []
    guard let annotation = allAnnotations.first(where: { $0.image == imageName }) else {
        return [] 
    }
    return annotation.annotations.map { coreMLAnnotation in
        if let matchingClass = classes.first(where: { $0.name == coreMLAnnotation.label }) {
            return ClassLabel(imageName: imageName,
                className: matchingClass.name,
                box: CGRect(
                    x: coreMLAnnotation.coordinates.x - coreMLAnnotation.coordinates.width / 2,
                    y: coreMLAnnotation.coordinates.y - coreMLAnnotation.coordinates.height / 2,
                    width: coreMLAnnotation.coordinates.width,
                    height: coreMLAnnotation.coordinates.height
                ),
                color: Color(matchingClass.color)
            )
        } else {
            let newClass = YOLOClass(
                name: coreMLAnnotation.label,
                color: .black, 
                occurrenceCount: 0
            )
            classes.append(newClass)
            return ClassLabel(
                imageName: imageName,
                className: newClass.name,
                box: CGRect(
                    x: coreMLAnnotation.coordinates.x - coreMLAnnotation.coordinates.width / 2,
                    y: coreMLAnnotation.coordinates.y - coreMLAnnotation.coordinates.height / 2,
                    width: coreMLAnnotation.coordinates.width,
                    height: coreMLAnnotation.coordinates.height
                ),
                color: Color(newClass.color)
            )
        }
    }
}
struct CoreMLAnnotation: Codable {
    struct Coordinates: Codable {
        let height: Double
        let width: Double
        let x: Double
        let y: Double
    }
    struct Annotation: Codable {
        let coordinates: Coordinates
        let label: String
    }
    var annotations: [Annotation]
    let image: String
}

//
//  filterBoundingBoxes.swift
//  labels
//
//  Created by Jacek Kałużny on 03/02/2025.
//


import SwiftUI
import CoreGraphics



var filterMethods = ["Closest 3 colors", "Average colors", "Closest color"]

func colorDistance(_ color1: Color, _ color2: Color) -> CGFloat {
    let (r1, g1, b1) = color1.rgbComponents()!
    let (r2, g2, b2) = color2.rgbComponents()!
    return sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))
}

func loadImagePixels(from url: URL) -> CGImage? {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        return nil
    }
    return image
}
func getPixelColor(image: CGImage, x: Int, y: Int) -> Color? {
    guard let data = image.dataProvider?.data,
          let ptr = CFDataGetBytePtr(data) else { return nil }

    let bytesPerPixel = image.bitsPerPixel / 8
    let bytesPerRow = image.bytesPerRow
    let index = (y * bytesPerRow) + (x * bytesPerPixel)

    let r = CGFloat(ptr[index]) / 255.0
    let g = CGFloat(ptr[index + 1]) / 255.0
    let b = CGFloat(ptr[index + 2]) / 255.0

    return Color(red: r, green: g, blue: b)
}

func samplePixels(image: CGImage, mask: CGImage, box: CGRect, count: Int, isMask: Bool) -> [Color] {
    var sampledColors: [Color] = []
    for _ in 0..<count {
        let x = Int(box.origin.x + CGFloat.random(in: 0..<box.width))
        let y = Int(box.origin.y + CGFloat.random(in: 0..<box.height))
        if let color = getPixelColor(image: image, x: x, y: y) {
            if let mcolor = getPixelColor(image: mask, x: x, y: y) {
                if((isBlack(color: mcolor) && !isMask) || (!isBlack(color: mcolor) && isMask))
                {
                    sampledColors.append(color)
                }
            }
        }
    }
    var countB = count - sampledColors.count
    if(countB > 0)
    {
        for _ in 0..<countB {
            let x = Int(box.origin.x + CGFloat.random(in: 0..<box.width))
            let y = Int(box.origin.y + CGFloat.random(in: 0..<box.height))
            if let color = getPixelColor(image: image, x: x, y: y) {
                if let mcolor = getPixelColor(image: mask, x: x, y: y) {
                    if((isBlack(color: mcolor) && !isMask) || (!isBlack(color: mcolor) && isMask))
                    {
                        sampledColors.append(color)
                    }
                }
            }
        }
    }
    return sampledColors
}

func isBlack(color: Color) -> Bool {
    let (r, g, b) = color.rgbComponents()!
    return r < 0.1 && g < 0.1 && b < 0.1
}
func filterBoundingBoxes(
    mainImageURL: URL,
    maskImageURL: URL,
    labels: inout [ClassLabel],
    objectColors: [Color],
    backgroundColors: [Color],
    speedAccuracyFactor: Int, // Higher values = more samples for accuracy
    numberOfLabelsScale: Double,
    sharedClasses: SharedClasses,
    method: String
) {
    switch method
    {
    case "Closest 3 colors":
        filterBoundingBoxesAvg(mainImageURL: mainImageURL, maskImageURL: maskImageURL, labels: &labels, objectColors: objectColors, backgroundColors: backgroundColors, speedAccuracyFactor: speedAccuracyFactor, numberOfLabelsScale: numberOfLabelsScale/100.0, sharedClasses: sharedClasses)
    case "Average colors":
        filterBoundingBoxes3(mainImageURL: mainImageURL, maskImageURL: maskImageURL, labels: &labels, objectColors: objectColors, backgroundColors: backgroundColors, speedAccuracyFactor: speedAccuracyFactor, numberOfLabelsScale: numberOfLabelsScale/100.0, sharedClasses: sharedClasses)
    default:
        filterBoundingBoxes1(mainImageURL: mainImageURL, maskImageURL: maskImageURL, labels: &labels, objectColors: objectColors, backgroundColors: backgroundColors, speedAccuracyFactor: speedAccuracyFactor, numberOfLabelsScale: numberOfLabelsScale/100.0, sharedClasses: sharedClasses)
    }
}
func filterBoundingBoxes1(
    mainImageURL: URL,
    maskImageURL: URL,
    labels: inout [ClassLabel],
    objectColors: [Color],
    backgroundColors: [Color],
    speedAccuracyFactor: Int, // Higher values = more samples for accuracy
    numberOfLabelsScale: Double,
    sharedClasses: SharedClasses
) {
    guard let mainImage = loadImagePixels(from: mainImageURL),
          let maskImage = loadImagePixels(from: maskImageURL) else {
        print("Error loading images.")
        return
    }

    let sampleCount = max(5, 10 / speedAccuracyFactor) // Adjust based on speed/accuracy tradeoff

    var filteredLabels: [ClassLabel] = []
    
    for label in labels {
        let box = label.box

        let maskPixels = samplePixels(image: mainImage, mask: maskImage, box: box, count: sampleCount, isMask: true)

        let objectDistance = maskPixels
            .map { minColorDistance(from: $0, to: objectColors) }
            .average() ?? CGFloat.infinity


        let inverseBackgroundDistance = maskPixels
            .map { minColorDistance(from: $0, to: backgroundColors) }
            .average() ?? CGFloat.infinity

        // Validate bounding box based on color distances
        if objectDistance < inverseBackgroundDistance * numberOfLabelsScale {
            filteredLabels.append(label)
        }
    }

    // Thread-safe update
    sharedClasses.lock.lock()
    labels = filteredLabels
    sharedClasses.lock.unlock()

    print("Filtered labels count: \(filteredLabels.count) / \(labels.count)")
}
func filterBoundingBoxes3(
    mainImageURL: URL,
    maskImageURL: URL,
    labels: inout [ClassLabel],
    objectColors: [Color],
    backgroundColors: [Color],
    speedAccuracyFactor: Int, // Higher values = more samples for accuracy
    numberOfLabelsScale: Double,
    sharedClasses: SharedClasses
) {
    guard let mainImage = loadImagePixels(from: mainImageURL),
          let maskImage = loadImagePixels(from: maskImageURL) else {
        print("Error loading images.")
        return
    }

    let sampleCount = max(5, 10 / speedAccuracyFactor) // Adjust based on speed/accuracy tradeoff

    var filteredLabels: [ClassLabel] = []
    
    for label in labels {
        let box = label.box

        let maskPixels = samplePixels(image: mainImage, mask: maskImage, box: box, count: sampleCount, isMask: true)

        let objectDistance = maskPixels
            .map { avgThreeClosestColorDistances(from: $0, to: objectColors) }
            .average() ?? CGFloat.infinity


        let inverseBackgroundDistance = maskPixels
            .map { avgThreeClosestColorDistances(from: $0, to: backgroundColors) }
            .average() ?? CGFloat.infinity

        // Validate bounding box based on color distances
        if objectDistance < inverseBackgroundDistance * numberOfLabelsScale {
            filteredLabels.append(label)
        }
    }

    // Thread-safe update
    sharedClasses.lock.lock()
    labels = filteredLabels
    sharedClasses.lock.unlock()

    print("Filtered labels count: \(filteredLabels.count) / \(labels.count)")
}
extension Array where Element == CGFloat {
    func average() -> CGFloat? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / CGFloat(count)
    }
}
func minColorDistance(from color: Color, to colorList: [Color]) -> CGFloat {
    guard let closestDistance = colorList.map({ colorDistance($0, color) }).min() else {
        return CGFloat.infinity // If color list is empty, return a large value
    }
    return closestDistance
}
func avgThreeClosestColorDistances(from color: Color, to colorList: [Color]) -> CGFloat {
    let sortedDistances = colorList.map { colorDistance($0, color) }.sorted()
    
    // Take the average of the three closest distances
    let closestDistances = sortedDistances.prefix(3)
    
    guard !closestDistances.isEmpty else { return CGFloat.infinity }
    
    return closestDistances.reduce(0, +) / CGFloat(closestDistances.count)
}


func filterBoundingBoxesAvg(
    mainImageURL: URL,
    maskImageURL: URL,
    labels: inout [ClassLabel],
    objectColors: [Color],
    backgroundColors: [Color],
    speedAccuracyFactor: Int, // Higher values = more samples for accuracy
    numberOfLabelsScale: Double, // Higher values = more samples for accuracy
    sharedClasses: SharedClasses
) {
    guard let mainImage = loadImagePixels(from: mainImageURL),
          let maskImage = loadImagePixels(from: maskImageURL) else {
        print("Error loading images.")
        return
    }

    let sampleCount = max(5, 10 / speedAccuracyFactor) // Adjust based on speed/accuracy tradeoff

    var filteredLabels: [ClassLabel] = []
    
    for label in labels {
        let box = label.box

        // Sample colors inside the mask
        let maskPixels = samplePixels(image: mainImage, mask: maskImage, box: box, count: sampleCount, isMask: true)
//        let mainPixels = samplePixels(image: mainImage, box: box, count: sampleCount)

        // Compute average minimum color distance
        
        var objectDistances = 0.0
        for objectColor in objectColors
        {
            let objectDistance = maskPixels
                .map { colorDistance($0, objectColor) }
                .average() ?? CGFloat.infinity
            objectDistances += objectDistance
        }

//        let backgroundDistance = mainPixels
//            .filter { isBlack(color: $0) }
//            .map { minColorDistance(from: $0, to: backgroundColors) }
//            .average() ?? CGFloat.infinity

//        let inverseObjectDistance = mainPixels
//            .filter { isBlack(color: $0) }
//            .map { minColorDistance(from: $0, to: objectColors) }
//            .average() ?? CGFloat.infinity
        
        var inverseBackgroundDistances = 0.0
        for backgroundColor in backgroundColors
        {
            let inverseBackgroundDistance = maskPixels
                .map { colorDistance($0, backgroundColor) }
                .average() ?? CGFloat.infinity
            inverseBackgroundDistances += inverseBackgroundDistance
        }
//        let inverseBackgroundDistance = maskPixels
//            .map { minColorDistance(from: $0, to: backgroundColors) }
//            .average() ?? CGFloat.infinity

        // Validate bounding box based on color distances
        if objectDistances < inverseBackgroundDistances * numberOfLabelsScale {
            filteredLabels.append(label)
        }
    }

    // Thread-safe update
    sharedClasses.lock.lock()
    labels = filteredLabels
    sharedClasses.lock.unlock()

    print("Filtered labels count: \(filteredLabels.count) / \(labels.count)")
}
extension Color {
    func rgbComponents() -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue)
        } else {
            return nil
        }
    }
}

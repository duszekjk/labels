import Foundation

// 🔹 Wrapper to allow shared access to `classes`
final class SharedClasses {
    var classes: [YOLOClass] = []
    let lock = NSLock()

    init(classes: [YOLOClass]) {
        self.classes = classes
    }
}

func applyToDatasetWithProgress(
    folderURL: URL,
    projectSettings: ProjectSettings,
    labelStorage: String,
    classes:  inout [YOLOClass],
    progress: @escaping (Double) -> Void,
    action: @escaping (URL, inout [ClassLabel], String, ProjectSettings, SharedClasses) -> Void,
    actionBefore: ((URL, inout [ClassLabel], String, ProjectSettings, SharedClasses) -> Void)? = nil
) {
    
    let sharedClasses = SharedClasses(classes: classes)
    do {
        let files = try FileManager.default.contentsOfDirectory(at: folderURL.appending(path: projectSettings.imageSubdirectory), includingPropertiesForKeys: nil)
        let totalFiles = files.count
        guard totalFiles > 0 else { return }

        if totalFiles < 50000 {
            var processedFiles = 0
            for file in files {
                processFile(
                    file: file,
                    folderURL: folderURL,
                    projectSettings: projectSettings,
                    labelStorage: labelStorage,
                    sharedClasses: sharedClasses,
                    action: action,
                    actionBefore: actionBefore
                )
                DispatchQueue.main.async {
                    processedFiles += 1
                    progress(Double(processedFiles) / Double(totalFiles))
                }
            }
            return
        }

        let cpuCores = ProcessInfo.processInfo.activeProcessorCount
        let numThreads = min(cpuCores, totalFiles / 10)
        let chunkSize = totalFiles / numThreads

        var processedFiles = 0
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)

        for i in 0..<numThreads {
            let startIdx = i * chunkSize
            let endIdx = (i == numThreads - 1) ? totalFiles : (i + 1) * chunkSize
            let fileChunk = Array(files[startIdx..<endIdx])

            dispatchGroup.enter()
            queue.async {
                for file in fileChunk {
                    autoreleasepool {
                        processFile(
                            file: file,
                            folderURL: folderURL,
                            projectSettings: projectSettings,
                            labelStorage: labelStorage,
                            sharedClasses: sharedClasses,
                            action: action,
                            actionBefore: actionBefore
                        )
                        
                        DispatchQueue.main.async {
                            sharedClasses.lock.lock()
                            
                                processedFiles += 1
                                progress(Double(processedFiles) / Double(totalFiles))
                            sharedClasses.lock.unlock()
                        }
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()
        classes = sharedClasses.classes

    } catch {
        print("❌ Failed to process dataset: \(error)")
    }
}

// 🔹 **Thread-safe function to process each file**
private func processFile(
    file: URL,
    folderURL: URL,
    projectSettings: ProjectSettings,
    labelStorage: String,
    sharedClasses: SharedClasses,
    action: (URL, inout [ClassLabel], String, ProjectSettings, SharedClasses) -> Void,
    actionBefore: ((URL, inout [ClassLabel], String, ProjectSettings, SharedClasses) -> Void)? = nil
) {
    let imageName = file.lastPathComponent
    var labels: [ClassLabel] = []
    var labelFileName: String?

    do {
        if let actionBefore = actionBefore {
            actionBefore(folderURL, &labels, imageName, projectSettings, sharedClasses)
        }
        
        sharedClasses.lock.lock()
        (labels, labelFileName) = loadLabelsFromFormat(labelStorage: labelStorage, filePath: folderURL.appending(path: projectSettings.labelSubdirectory), imageName: imageName, classes: &sharedClasses.classes)
        sharedClasses.lock.unlock()

        guard !labels.isEmpty else { return }

        action(folderURL, &labels, imageName, projectSettings, sharedClasses)

        if let labelFileName = labelFileName {
            sharedClasses.lock.lock()
            var classesNow = sharedClasses.classes
            sharedClasses.lock.unlock()
            saveLabelsInFormat(labelStorage: labelStorage, filePath: folderURL.appending(path: projectSettings.labelSubdirectory), labelFileName: labelFileName, imageName: imageName, labels: labels, classes: &classesNow)
        }
    } catch {
        print("❌ Failed to process image \(imageName): \(error)")
    }
}


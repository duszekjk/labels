import SwiftUI

struct TrainingView: View {
    @Binding var projectSettings: ProjectSettings
    let folderURL: URL
    @State private var isTraining = false
    @State private var progress: Float = 0.0
    @State private var trainingLogs: [String] = []
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            Text("Training Model")
                .font(.largeTitle)
                .padding()
            
            // Progress View
            if isTraining {
                VStack {
                    ProgressView(value: progress)
                        .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(trainingLogs, id: \.self) { log in
                                Text(log)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 200)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding()
                }
            } else {
                Text("Start fine-tuning your model with the labeled dataset.")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            // Training Button
            Button(action: {
                startTraining()
            }) {
                Text(isTraining ? "Training in Progress..." : "Start Training")
                    .padding()
                    .background(isTraining ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isTraining)
            
            // Error Message
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    func startTraining() {
        isTraining = true
        progress = 0.0
        trainingLogs = []
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Prepare dataset
                let dataset = try prepareDataset()
                trainingLogs.append("Dataset prepared with \(dataset.images.count) images and \(dataset.labels.count) annotations.")
                
                // Start training
                let numClasses = projectSettings.classes.count
                let trainedModelPath = try fineTuneModel(dataset: dataset, numClasses: numClasses)
                
                DispatchQueue.main.async {
                    progress = 1.0
                    trainingLogs.append("Model training completed.")
                    trainingLogs.append("Trained model saved to \(trainedModelPath.path).")
                    isTraining = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isTraining = false
                }
            }
        }
    }
    
    func prepareDataset() throws -> (images: [URL], labels: [URL]) {
        // Collect all labeled images
        let labeledImages = projectSettings.classes.flatMap { $0.name }
        var images: [URL] = []
        var labels: [URL] = []
        
        for file in try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) {
            if file.pathExtension == "jpg" || file.pathExtension == "png" {
                let labelFile = file.deletingPathExtension().appendingPathExtension("txt")
                if FileManager.default.fileExists(atPath: labelFile.path) {
                    images.append(file)
                    labels.append(labelFile)
                }
            }
        }
        
        guard !images.isEmpty else {
            throw NSError(domain: "TrainingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No labeled images found."])
        }
        
        return (images, labels)
    }
    
    func fineTuneModel(dataset: (images: [URL], labels: [URL]), numClasses: Int) throws -> URL {
        // Example fine-tuning using Core ML or exporting to a training script
        let modelPath = folderURL.appendingPathComponent("fine_tuned_model.mlmodelc")
        
        // Simulate training progress
        for i in 1...10 {
            DispatchQueue.main.async {
                progress = Float(i) / 10.0
                trainingLogs.append("Training progress: \(Int(progress * 100))%")
            }
            Thread.sleep(forTimeInterval: 0.5) // Simulate training delay
        }
        
        // Save model (replace with actual training logic)
        let trainedModel = "Trained YOLO Model with \(numClasses) classes"
        try trainedModel.write(to: modelPath, atomically: true, encoding: .utf8)
        
        return modelPath
    }
}

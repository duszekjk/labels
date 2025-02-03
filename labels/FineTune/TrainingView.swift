
import SwiftUI
import CreateML
import Vision
struct TrainingView: View {
    @State private var progress: Float = 0.0
    @State private var isTraining = false
    @State private var errorMessage: String?
    let datasetPath: URL
    @Binding var show: Bool
    var body: some View {
        VStack {
            HStack
            {
                Spacer()
                Button("Done") {
                    show = false
                }
                .padding()
            }
            Spacer()
            if isTraining {
                ProgressView(value: progress)
                    .padding()
                    .onAppear {
                        startTraining()
                    }
            } else {
                Button("Start Training") {
                    isTraining = true
                }
                .padding()
            }
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    func startTraining() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let startModelPath = Bundle.main.url(forResource: "yolov8s_updatable", withExtension: "mlmodelc") else {
                    fatalError("❌ Model not found in the app bundle.")
                }
                let modelPath = try fineTuneObjectDetectionModel(modelPath: startModelPath, dataset: datasetPath)
                DispatchQueue.main.async {
                    isTraining = false
                    print("Model trained and saved at \(modelPath)")
                }
            } catch {
                DispatchQueue.main.async {
                    isTraining = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
func prepareBoundingBoxData(dataset: URL, modelPath: URL) throws -> MLBatchProvider {
    var featureProviders: [MLFeatureProvider] = []
    guard let imageConstraint = try getImageConstraint(from: modelPath) else {
        throw NSError(domain: "ImageConstraintError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Image constraint not found in model."])
    }
    let jsonFile = dataset.appendingPathComponent("coreml_annotations.json")
    let jsonData = try Data(contentsOf: jsonFile)
    let annotations = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [[String: Any]]
    for annotation in annotations {
        guard let imageName = annotation["image"] as? String,
              let imageAnnotations = annotation["annotations"] as? [[String: Any]],
              let imagePath = dataset.appendingPathComponent(imageName) as URL?,
              let image = try? MLFeatureValue(imageAt: imagePath, constraint: imageConstraint) else {
            continue
        }
        for object in imageAnnotations {
            guard let label = object["label"] as? String,
                  let coordinates = object["coordinates"] as? [String: CGFloat],
                  let x = coordinates["x"],
                  let y = coordinates["y"],
                  let width = coordinates["width"],
                  let height = coordinates["height"] else {
                continue
            }
            let normalizedX = x / CGFloat(imageConstraint.pixelsWide)
            let normalizedY = y / CGFloat(imageConstraint.pixelsHigh)
            let normalizedWidth = width / CGFloat(imageConstraint.pixelsWide)
            let normalizedHeight = height / CGFloat(imageConstraint.pixelsHigh)
            let features: [String: MLFeatureValue] = [
                "image": image,
                "label": MLFeatureValue(string: label),
                "x": MLFeatureValue(double: Double(normalizedX)),
                "y": MLFeatureValue(double: Double(normalizedY)),
                "width": MLFeatureValue(double: Double(normalizedWidth)),
                "height": MLFeatureValue(double: Double(normalizedHeight))
            ]
            let featureProvider = try MLDictionaryFeatureProvider(dictionary: features)
            featureProviders.append(featureProvider)
        }
    }
    return MLArrayBatchProvider(array: featureProviders)
}
func fineTuneObjectDetectionModel(modelPath: URL, dataset: URL) throws {
    let config = MLModelConfiguration()
    config.computeUnits = .all
    let trainingData = try prepareBoundingBoxData(dataset: dataset, modelPath: modelPath)
    let updateTask = try MLUpdateTask(
        forModelAt: modelPath,
        trainingData: trainingData,
        configuration: config,
        completionHandler: { context in
            if context.task.error != nil {
                print("❌ Training failed with error: \(context.task.error!.localizedDescription)")
            } else if context.task.state == .completed {
                print("✅ Training completed successfully.")
                let fineTunedModelPath = dataset.appendingPathComponent("FineTunedObjectDetection.mlmodel")
                do {
                    try context.model.write(to: fineTunedModelPath)
                    print("✅ Fine-tuned model saved at: \(fineTunedModelPath)")
                } catch {
                    print("❌ Failed to save fine-tuned model: \(error.localizedDescription)")
                }
            } else {
                print("⚠️ Training did not complete: \(context.task.state)")
            }
        }
    )
    updateTask.resume()
}
func getImageConstraint(from modelPath: URL) throws -> MLImageConstraint? {
    let model = try MLModel(contentsOf: modelPath)
    for (inputName, input) in model.modelDescription.inputDescriptionsByName {
        if input.type == .image {
            return input.imageConstraint
        }
    }
    return nil
}

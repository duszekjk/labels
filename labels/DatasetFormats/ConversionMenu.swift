
import SwiftUI
struct ConversionMenu: View {
    let currentFormat: String
    let datasetType: DatasetType
    let folderURL: URL
    @Binding var projectSettings: ProjectSettings
    @Binding var labels: [ClassLabel]
    let imageName: String
    @State private var selectedFormat: String = ""
    @State private var isConverting: Bool = false
    @State private var progress: Double = 0.0
    var body: some View {
        VStack {
            if isConverting {
                ProgressViewWithEstimation("Converting...", value: progress, total: 1.0)
                    .padding()
            }
            else
            {
                Text("Current Format: \(currentFormat)")
                    .font(.headline)
                Text(labelStorageFormats.first { $0.name == currentFormat }?.description ?? "")
                    .font(.subheadline)
                    .padding(.bottom)
                Picker("Convert to:", selection: $selectedFormat) {
                    ForEach(labelStorageFormats.filter { $0.supportedDatasetTypes.contains(datasetType) }, id: \.id) { format in
                        Text(format.name).tag(format.name)
                    }
                }
                .onAppear()
                {
                    if(selectedFormat == "")
                    {
                        selectedFormat = currentFormat
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                if let targetFormat = labelStorageFormats.first(where: { $0.name == selectedFormat }) {
                    Text("Target Format: \(targetFormat.name)")
                        .font(.headline)
                    Text(targetFormat.description)
                        .font(.subheadline)
                        .padding(.bottom)
                }
                Button("Convert") {
                    startConversion(to: selectedFormat)
                }
                .disabled(selectedFormat.isEmpty || isConverting || selectedFormat == currentFormat)
                .padding()
            }
        }
        .padding()
    }
    private func startConversion(to targetFormat: String) {
        guard !targetFormat.isEmpty else { return }
        isConverting = true
        progress = 0.0
        DispatchQueue.global(qos: .userInitiated).async {
            convertDatasetWithProgress(
                folderURL: folderURL,
                sourceLabelStorage: currentFormat,
                targetLabelStorage: targetFormat,
                projectSettings: projectSettings,
                classes: &projectSettings.classes
            ) { progressValue in
                DispatchQueue.main.async {
                    progress = progressValue
                }
            }
            DispatchQueue.main.async {
                isConverting = false
                projectSettings.labelStorage = targetFormat
                let projectSettingsMenager = ProjectSettingsManager(settings: projectSettings, directoryURL: folderURL)
                projectSettingsMenager.settings = projectSettings
                projectSettingsMenager.saveSettings()
            }
        }
    }
}
func convertDatasetWithProgress(
    folderURL: URL,
    sourceLabelStorage: String,
    targetLabelStorage: String,
    projectSettings: ProjectSettings,
    classes: inout [YOLOClass],
    progress: @escaping (Double) -> Void
) {
    print("converting to \(targetLabelStorage)")
    var localClasses = classes
    applyToDatasetWithProgress(
        folderURL: folderURL, projectSettings: projectSettings,
        labelStorage: sourceLabelStorage,
        classes: &localClasses,
        progress: progress
    ) { fileURL, labels, imageName, _, classesNow in
        let newExtension: String
        switch targetLabelStorage {
        case "COCO JSON", "Pascal VOC JSON", "YOLO JSON", "LabelMe JSON", "CoreML JSON":
            newExtension = "json"
        case "Pascal VOC CSV", "Single CSV File", "Per-Image CSV":
            newExtension = "csv"
        default:
            newExtension = "txt" 
        }
        let newLabelFileName = fileURL.deletingPathExtension().lastPathComponent + "." + newExtension
        classesNow.lock.lock()
        saveLabelsInFormat(
            labelStorage: targetLabelStorage,
            filePath: folderURL,
            labelFileName: newLabelFileName,
            imageName: imageName,
            labels: labels, classes: &classesNow.classes
        )
        classesNow.lock.unlock()
    }
}

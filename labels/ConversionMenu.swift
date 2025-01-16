//
//  ConversionMenu.swift
//  labels
//
//  Created by Jacek Kałużny on 14/01/2025.
//


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
            .pickerStyle(MenuPickerStyle())
            .padding()

            if let targetFormat = labelStorageFormats.first(where: { $0.name == selectedFormat }) {
                Text("Target Format: \(targetFormat.name)")
                    .font(.headline)
                Text(targetFormat.description)
                    .font(.subheadline)
                    .padding(.bottom)
            }

            if isConverting {
                ProgressView("Converting...", value: progress, total: 1.0)
                    .padding()
            }

            Button("Convert") {
                startConversion(to: selectedFormat)
            }
            .disabled(selectedFormat.isEmpty || isConverting)
            .padding()
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
                classes: &projectSettings.classes
            ) { progressValue in
                DispatchQueue.main.async {
                    progress = progressValue
                }
            }

            DispatchQueue.main.async {
                isConverting = false
                projectSettings.labelStorage = targetFormat
            }
        }
    }
}

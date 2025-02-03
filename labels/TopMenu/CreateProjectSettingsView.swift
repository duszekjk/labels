
import SwiftUI
struct CreateProjectSettingsView: View {
    let datasetType: DatasetType
    //@Binding
    var folderUrl: URL?
    @State public var name: String = ""
    @State public var description: String = ""
    @State public var icon: String = ""
    @State public var hashtags: String = ""
    @State public var labelStorage: LabelStorageFormat? = nil
    @State public var editing: Bool = false
    @Binding var projectSettings: ProjectSettings
    @Binding var showGetData: Bool
    var filteredLabelStorageFormats: [LabelStorageFormat] {
            switch datasetType {
            case .classification:
                return labelStorageFormats.filter { $0.name == "Class Subfolders" || $0.name.contains("CSV") }
            case .boundingBox:
                return labelStorageFormats.filter { $0.name.contains("Bounding") || $0.name.contains("YOLO") }
            case .instanceSegmentation:
                return labelStorageFormats.filter { $0.name.contains("COCO") || $0.name.contains("Polygon") }
            case .semanticSegmentation:
                return labelStorageFormats.filter { $0.name.contains("JSON") || $0.name.contains("Per-Image") }
            case .none:
                return []
            }
        }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Create Project Settings")
                .font(.title)
                .padding(.bottom, 10)
            TextField("Project Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Description", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Icon Path (Optional)", text: $icon)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Hashtags (comma-separated)", text: $hashtags)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Picker("Label Storage Format", selection: $labelStorage) {
                ForEach(filteredLabelStorageFormats) { format in
                    Text(format.name).tag(Optional(format))
                }
            }
            if let selectedFormat = labelStorage {
                Text(selectedFormat.description)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: createProjectSettings) {
                Text(editing ? "Save Settings": "Create and Save Settings")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(folderUrl == nil || name.isEmpty || labelStorage == nil)
        }
        .padding()
        .onAppear(perform: setDefaultLabelStorage)
    }
    private func setDefaultLabelStorage() {
            if labelStorage == nil {
                switch datasetType {
                case .classification:
                    labelStorage = labelStorageFormats.first(where: { $0.name == "Class Subfolders" })
                case .boundingBox:
                    labelStorage = labelStorageFormats.first(where: { $0.name == "YOLO JSON" })
                case .instanceSegmentation:
                    labelStorage = labelStorageFormats.first(where: { $0.name == "COCO JSON" })
                case .semanticSegmentation:
                    labelStorage = labelStorageFormats.first(where: { $0.name == "Single JSON File" })
                case .none:
                    labelStorage = labelStorageFormats.first
                }
            }
        }
    private func createProjectSettings() {
        guard let folderUrl = folderUrl, let labelStorage = labelStorage else { return }
        let hashtagsArray = hashtags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        var newSettings = ProjectSettings(
            name: name,
            description: description,
            icon: icon.isEmpty ? nil : icon,
            hashtags: hashtagsArray,
            datasetType: datasetType,
            labelStorage: labelStorage.name,
            creationDate: Date(),
            lastModifiedDate: Date(),
            directoryPath: folderUrl.path,
            classes: []
        )
        if(editing)
        {
            newSettings = projectSettings
            newSettings.name = name
            newSettings.description = description
            newSettings.icon = icon
            newSettings.hashtags = hashtagsArray
            newSettings.labelStorage = labelStorage.name
            
        }
        let manager = ProjectSettingsManager(settings: newSettings, directoryURL: folderUrl)
        projectSettings = newSettings
        manager.saveSettings()
        showGetData = false
    }
}

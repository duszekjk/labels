import SwiftUI

struct CreateProjectSettingsView: View {
    @Binding var folderUrl: URL?
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var icon: String = ""
    @State private var hashtags: String = ""
    @State private var datasetType: DatasetType = .classification
    @State private var labelStorage: String = "default"

    @Binding var projectSettings: ProjectSettings?

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

            Picker("Dataset Type", selection: $datasetType) {
                ForEach(DatasetType.allCases, id: \. self) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            TextField("Label Storage Format", text: $labelStorage)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Spacer()

            Button(action: createProjectSettings) {
                Text("Create and Save Settings")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(folderUrl == nil || name.isEmpty)

        }
        .padding()
    }

    private func createProjectSettings() {
        guard let folderUrl = folderUrl else { return }

        let hashtagsArray = hashtags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let newSettings = ProjectSettings(
            name: name,
            description: description,
            icon: icon.isEmpty ? nil : icon,
            hashtags: hashtagsArray,
            datasetType: datasetType,
            labelStorage: labelStorage,
            creationDate: Date(),
            lastModifiedDate: Date(),
            directoryPath: folderUrl.path
        )

        // Save settings to the specified folder
        let manager = ProjectSettingsManager(settings: newSettings, directoryURL: folderUrl)
        projectSettings = newSettings
        manager.saveSettings()
    }
}

// MARK: - Preview
struct CreateProjectSettingsView_Previews: PreviewProvider {
    @State static var folderUrl: URL? = nil
    @State static var projectSettings: ProjectSettings? = nil

    static var previews: some View {
        CreateProjectSettingsView(folderUrl: $folderUrl, projectSettings: $projectSettings)
    }
}

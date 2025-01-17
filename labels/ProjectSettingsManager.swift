
import SwiftUI
struct ProjectSettings: Codable {
    var name: String
    var description: String
    var icon: String?
    var hashtags: [String]
    var datasetType: DatasetType
    var labelStorage: String 
    var creationDate: Date
    var lastModifiedDate: Date
    var directoryPath: String
    var selectedClass: YOLOClass?
    var classes: [YOLOClass]
}
class ProjectSettingsManager: ObservableObject {
    @Published var settings: ProjectSettings {
        didSet {
            saveSettings()
        }
    }
    private var directoryURL: URL?
    init(settings: ProjectSettings? = nil, directoryURL: URL? = nil) {
        self.directoryURL = directoryURL
        if let settings = settings {
            self.settings = settings
        } else {
            self.settings = ProjectSettings(
                name: "New Project",
                description: "Default description",
                icon: nil,
                hashtags: [],
                datasetType: .classification,
                labelStorage: "default",
                creationDate: Date(),
                lastModifiedDate: Date(),
                directoryPath: "", classes: []
            )
            if directoryURL != nil {
                print("loading settigs")
                loadSettings(directoryURL: directoryURL!)
            }
            else
            {
                    print("loading settigs error with path \(directoryURL)")
            }
        }
    }
    public func saveSettings() {
        guard let directoryURL = directoryURL else {
            print("No directory selected for saving settings.")
            return
        }
        do {
            let data = try JSONEncoder().encode(settings)
            let fileURL = directoryURL.appendingPathComponent("settings.json")
            try data.write(to: fileURL)
            print("Settings saved to \(fileURL)")
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    func loadSettings(directoryURL: URL) {
        let fileURL = directoryURL.appendingPathComponent("settings.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No settings file found at \(fileURL)")
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let loadedSettings = try JSONDecoder().decode(ProjectSettings.self, from: data)
            self.settings = loadedSettings
            print("Settings loaded from \(fileURL)")
        } catch {
            print("Error loading settings: \(error)")
        }
        var uniqueClasses = self.settings.classes
        uniqueClasses = Array(
            Dictionary(grouping: uniqueClasses, by: \.name) 
                .compactMapValues { $0.first }       
                .values                              
        ).sorted { $0.name < $1.name }               
        self.settings.classes = uniqueClasses
    }
    func updateDirectory(url: URL) {
        self.directoryURL = url
        self.settings.directoryPath = url.path
        saveSettings()
    }
}

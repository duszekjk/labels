class ProjectSettingsManager: ObservableObject {
    @Published var settings: ProjectSettings {
        didSet {
            saveSettings()
        }
    }
    
    init(settings: ProjectSettings) {
        self.settings = settings
    }
    
    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            let url = getSettingsFileURL()
            try data.write(to: url)
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    private func getSettingsFileURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("project_settings.json")
    }
    
    func loadSettings() {
        let url = getSettingsFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let loadedSettings = try JSONDecoder().decode(ProjectSettings.self, from: data)
            self.settings = loadedSettings
        } catch {
            print("Error loading settings: \(error)")
        }
    }
}
class ProjectDirectoryManager: ObservableObject {
    @Published var directoryPath: URL?
    
    init() {
        if let storedPath = UserDefaults.standard.string(forKey: "ProjectDirectoryPath") {
            self.directoryPath = URL(fileURLWithPath: storedPath)
            self.directoryPath?.startAccessingSecurityScopedResource()
        }
    }
    
    func saveDirectoryPath(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: "ProjectDirectoryPath")
        url.startAccessingSecurityScopedResource()
        self.directoryPath = url
    }
    
    func clearDirectoryPath() {
        directoryPath?.stopAccessingSecurityScopedResource()
        UserDefaults.standard.removeObject(forKey: "ProjectDirectoryPath")
        self.directoryPath = nil
    }
}

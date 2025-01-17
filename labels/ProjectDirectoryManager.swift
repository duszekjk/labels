import SwiftUI
class ProjectDirectoryManager: ObservableObject {
    @Published var directoryPath: URL? {
        didSet {
            if let path = directoryPath {
                saveDirectoryPath(path)
            }
        }
    }
    init() {
        if let storedPath = UserDefaults.standard.string(forKey: "ProjectDirectoryPath") {
            self.directoryPath = URL(fileURLWithPath: storedPath)
            self.directoryPath?.startAccessingSecurityScopedResource()
            print("✅ Restored directory path: \(storedPath)")
        }
    }
    func saveDirectoryPath(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: "ProjectDirectoryPath")
        url.startAccessingSecurityScopedResource()
        print("✅ Directory path saved: \(url.path)")
    }
    func clearDirectoryPath() {
        directoryPath?.stopAccessingSecurityScopedResource()
        UserDefaults.standard.removeObject(forKey: "ProjectDirectoryPath")
        self.directoryPath = nil
    }
}

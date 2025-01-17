import Foundation
class FolderAccessManager: ObservableObject {
    @Published var folderURL: URL?
    private let folderKey = "SavedFolderPath"
    init() {
        loadSavedFolderPath()
    }
    private func saveFolderPath(folderURL: URL) {
        UserDefaults.standard.set(folderURL.path, forKey: folderKey)
        print("✅ Folder path saved: \(folderURL.path)")
    }
    private func loadSavedFolderPath() {
        guard let path = UserDefaults.standard.string(forKey: folderKey) else {
            print("⚠️ No saved folder path found.")
            return
        }
        let folderURL = URL(fileURLWithPath: path)
        if folderURL.startAccessingSecurityScopedResource() {
            self.folderURL = folderURL
            print("✅ Security-scoped resource access restored for: \(folderURL.path)")
        } else {
            print("❌ Failed to restore security-scoped resource access.")
        }
    }
    func loadExistingProjectSettings(fileURL: URL) {
        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            let folderURL = fileURL.deletingLastPathComponent()
            self.folderURL = folderURL
            saveFolderPath(folderURL: folderURL)
            print("✅ Project loaded successfully from folder: \(folderURL.path)")
        } else {
            print("❌ Failed to start security-scoped access for file: \(fileURL.path)")
        }
    }
}

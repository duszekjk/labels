import Foundation

class FolderAccessManager: ObservableObject {
    @Published var folderURL: URL?
    
    init() {
        loadFolderBookmark()
    }
    
    /// Save a folder as a bookmark
    func saveFolderBookmark(url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: "FolderBookmark")
            folderURL = url
            print("✅ Folder bookmarked successfully: \(url.path)")
        } catch {
            print("❌ Failed to save folder bookmark: \(error)")
        }
    }
    
    /// Load a folder from a saved bookmark
    func loadFolderBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: "FolderBookmark") else {
            print("⚠️ No folder bookmark found.")
            return
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("⚠️ Bookmark is stale, needs updating.")
            }
            
            folderURL = url
            if url.startAccessingSecurityScopedResource() {
                print("✅ Security-scoped resource access started: \(url.path)")
            } else {
                print("❌ Failed to start security-scoped resource access.")
            }
        } catch {
            print("❌ Failed to load folder bookmark: \(error)")
        }
    }
    
    /// Stop accessing folder
    func stopAccessingFolder() {
        folderURL?.stopAccessingSecurityScopedResource()
        folderURL = nil
    }
}

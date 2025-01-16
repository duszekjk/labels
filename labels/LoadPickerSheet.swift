import SwiftUI
import UniformTypeIdentifiers

struct LoadPickerSheet: UIViewControllerRepresentable {
    let onFilePicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.json],
            asCopy: false
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onFilePicked: onFilePicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFilePicked: (URL) -> Void
        
        init(onFilePicked: @escaping (URL) -> Void) {
            self.onFilePicked = onFilePicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let fileURL = urls.first else {
                print("⚠️ No file selected.")
                return
            }
            let folderURL = fileURL.deletingLastPathComponent()
            print("✅ Load: user selected settings.json at \(fileURL.path)")
            
            // Now we have the actual folder path
            if folderURL.startAccessingSecurityScopedResource() {
                print("✅ Security-scoped resource started for: \(folderURL.path)")
            } else {
                print("❌ Failed to start security scope for: \(folderURL.path)")
            }
            
            onFilePicked(folderURL)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("⚠️ Load was cancelled.")
        }
    }
}

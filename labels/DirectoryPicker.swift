import SwiftUI
import UniformTypeIdentifiers

struct DirectoryPicker: UIViewControllerRepresentable {
    @Binding var selectedDirectory: URL?
    var onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.folder],
            asCopy: false
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(selectedDirectory: $selectedDirectory, onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        @Binding var selectedDirectory: URL?
        var onDismiss: () -> Void
        
        init(selectedDirectory: Binding<URL?>, onDismiss: @escaping () -> Void) {
            self._selectedDirectory = selectedDirectory
            self.onDismiss = onDismiss
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            selectedDirectory = url
            url.startAccessingSecurityScopedResource()
            onDismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onDismiss()
        }
    }
}

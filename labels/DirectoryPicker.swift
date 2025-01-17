import SwiftUI
import UniformTypeIdentifiers
struct FolderPicker: View {
    @Binding var folderURL: URL?
    @Binding var workflowStep: WorkflowStep
    @Binding var showSavePicker: Bool
    var body: some View {
        #if os(macOS)
        MacFolderPicker(folderURL: $folderURL, workflowStep: $workflowStep, showSavePicker: $showSavePicker)
        #else
        IOSFolderPicker(folderURL: $folderURL, workflowStep: $workflowStep)
        #endif
    }
}
#if os(macOS)
struct MacFolderPicker: NSViewRepresentable {
    @Binding var folderURL: URL?
    @Binding var workflowStep: WorkflowStep
    @Binding var showSavePicker: Bool
    func makeNSView(context: Context) -> NSView {
        let button = NSButton(title: "Select Folder", target: context.coordinator, action: #selector(context.coordinator.openPanel))
        return button
    }
    func updateNSView(_ nsView: NSView, context: Context) {
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject {
        var parent: MacFolderPicker
        init(_ parent: MacFolderPicker) {
            self.parent = parent
        }
        @objc func openPanel() {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            if panel.runModal() == .OK, let url = panel.url {
                parent.folderURL = url
                print("selected url \(parent.folderURL!)")
                parent.showSavePicker = false
            }
        }
    }
}
#else
struct IOSFolderPicker: UIViewControllerRepresentable {
    @Binding var folderURL: URL?
    @Binding var workflowStep: WorkflowStep
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [UTType.folder.identifier], in: .open)
        documentPicker.delegate = context.coordinator
        documentPicker.allowsMultipleSelection = false
        return documentPicker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        print("updateUIViewController")
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: IOSFolderPicker
        init(_ parent: IOSFolderPicker) {
            self.parent = parent
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            print("getting url")
            let urlAcc = url.startAccessingSecurityScopedResource()
            print("accessing url: \(urlAcc)")
            parent.folderURL = url
            print("selected url \(parent.folderURL!)")
            parent.workflowStep = .ready
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled")
        }
    }
}
#endif

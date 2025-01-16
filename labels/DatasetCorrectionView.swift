struct DatasetCorrectionView: View {
    let folderURL: URL
    @Binding var projectSettings: ProjectSettings
    @State private var progress: Double = 0.0
    @State private var isProcessing = false
    @State private var oldClassName: String = ""
    @State private var newClassName: String = ""
    @State private var scaleFactor: CGFloat = 1.0
    @State private var shiftX: CGFloat = 0.0
    @State private var shiftY: CGFloat = 0.0
    
    var body: some View {
        VStack {
            // Rename Class
            Section {
                TextField("Old Class Name", text: $oldClassName)
                TextField("New Class Name", text: $newClassName)
                Button("Rename Class") {
                    isProcessing = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        renameClass(
                            folderURL: folderURL,
                            labelStorage: projectSettings.labelStorage,
                            classes: &projectSettings.classes,
                            oldClassName: oldClassName,
                            newClassName: newClassName
                        ) { progressValue in
                            DispatchQueue.main.async {
                                progress = progressValue
                            }
                        }
                        DispatchQueue.main.async {
                            isProcessing = false
                        }
                    }
                }
            }
            
            // Resize Boxes
            Section {
                Stepper("Scale Factor: \(scaleFactor, specifier: "%.2f")", value: $scaleFactor, in: 0.1...5.0, step: 0.1)
                Button("Resize All Boxes") {
                    isProcessing = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        resizeBoxes(
                            folderURL: folderURL,
                            labelStorage: projectSettings.labelStorage,
                            classes: &projectSettings.classes,
                            scaleFactor: scaleFactor
                        ) { progressValue in
                            DispatchQueue.main.async {
                                progress = progressValue
                            }
                        }
                        DispatchQueue.main.async {
                            isProcessing = false
                        }
                    }
                }
            }
            
            // Shift Boxes
            Section {
                Stepper("Shift X: \(shiftX, specifier: "%.1f")", value: $shiftX, in: -100.0...100.0, step: 1.0)
                Stepper("Shift Y: \(shiftY, specifier: "%.1f")", value: $shiftY, in: -100.0...100.0, step: 1.0)
                Button("Shift All Boxes") {
                    isProcessing = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        shiftBoxes(
                            folderURL: folderURL,
                            labelStorage: projectSettings.labelStorage,
                            classes: &projectSettings.classes,
                            shiftX: shiftX,
                            shiftY: shiftY
                        ) { progressValue in
                            DispatchQueue.main.async {
                                progress = progressValue
                            }
                        }
                        DispatchQueue.main.async {
                            isProcessing = false
                        }
                    }
                }
            }
            
            // Progress Bar
            if isProcessing {
                ProgressView(value: progress)
                    .padding()
            }
        }
        .padding()
    }
}

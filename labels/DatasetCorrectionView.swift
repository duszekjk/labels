
import SwiftUI
import SwiftUI
import SwiftUI
struct DatasetCorrectionView: View {
    let folderURL: URL
    @Binding var projectSettings: ProjectSettings
    @Environment(\.presentationMode) var presentationMode 
    @State private var progress: Double = 0.0
    @State private var isProcessing = false
    @State private var selectedOldClassName: String = "Select class"
    @State private var selectedNewClassName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var scaleFactor: CGFloat = 1.0
    @State private var shiftX: CGFloat = 0.0
    @State private var shiftY: CGFloat = 0.0
    @State private var scaleX: CGFloat = 1.0
    @State private var scaleY: CGFloat = 1.0
    @State private var shiftMode: String = "Relative to box size" 
    let shiftModes = ["Relative to box size", "Relative to image size", "Value in pixels"]
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Section {
                    Text("Rename Class")
                        .font(.headline)
                    HStack {
                        Picker("Select Old Class", selection: $selectedOldClassName) {
                            ForEach(projectSettings.classes, id: \.name) { yoloClass in
                                Text(yoloClass.name).tag(yoloClass.name)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedOldClassName) { newValue in
                            updateClassDetails(for: newValue)
                        }
                        ColorPicker("change to ", selection: $selectedColor)
                        TextField("New Class Name", text: $selectedNewClassName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Save changes") {
                            isProcessing = true
                            DispatchQueue.global(qos: .userInitiated).async {
                                renameClass(
                                    folderURL: folderURL,
                                    labelStorage: projectSettings.labelStorage,
                                    classes: &projectSettings.classes,
                                    oldClassName: selectedOldClassName,
                                    newClassName: selectedNewClassName,
                                    newColor: selectedColor
                                ) { progressValue in
                                    DispatchQueue.main.async {
                                        progress = progressValue
                                    }
                                }
                                DispatchQueue.main.async {
                                    saveProjectSettings()
                                    isProcessing = false
                                }
                            }
                        }
                    }
                }
                Divider()
                Section {
                    Text("Resize All Boxes")
                        .font(.headline)
                    HStack {
                        Picker("Resize Mode", selection: $shiftMode) {
                            ForEach(shiftModes, id: \.self) { mode in
                                Text(mode).tag(mode)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 200)
                        Stepper("Scale Factor: \(scaleFactor, specifier: "%.2f")", value: $scaleFactor, in: 0.1...5.0, step: 0.1)
                        Button("Resize Boxes") {
                            isProcessing = true
                            DispatchQueue.global(qos: .userInitiated).async {
                                resizeBoxes(
                                    folderURL: folderURL,
                                    labelStorage: projectSettings.labelStorage,
                                    classes: &projectSettings.classes,
                                    scaleFactor: scaleFactor,
                                    mode: shiftMode
                                ) { progressValue in
                                    DispatchQueue.main.async {
                                        progress = progressValue
                                    }
                                }
                                DispatchQueue.main.async {
                                    saveProjectSettings()
                                    isProcessing = false
                                }
                            }
                        }
                    }
                }
                Divider()
                Section {
                    Text("Shift All Boxes")
                        .font(.headline)
                    VStack(spacing: 10) {
                        Picker("Shift Mode", selection: $shiftMode) {
                            ForEach(shiftModes, id: \.self) { mode in
                                Text(mode).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        HStack {
                            Stepper("Shift X: \(shiftX, specifier: "%.1f") px", value: $shiftX, in: -100.0...100.0, step: 1.0)
                            Stepper("Shift Y: \(shiftY, specifier: "%.1f") px", value: $shiftY, in: -100.0...100.0, step: 1.0)
                        }
                        HStack {
                            Stepper("Scale X: \(scaleX, specifier: "%.2f")", value: $scaleX, in: 0.1...5.0, step: 0.1)
                            Stepper("Scale Y: \(scaleY, specifier: "%.2f")", value: $scaleY, in: 0.1...5.0, step: 0.1)
                        }
                        Button("Shift Boxes") {
                            isProcessing = true
                            DispatchQueue.global(qos: .userInitiated).async {
                                shiftBoxes(
                                    folderURL: folderURL,
                                    labelStorage: projectSettings.labelStorage,
                                    classes: &projectSettings.classes,
                                    shiftX: shiftX,
                                    shiftY: shiftY,
                                    scaleX: scaleX,
                                    scaleY: scaleY,
                                    mode: shiftMode
                                ) { progressValue in
                                    DispatchQueue.main.async {
                                        progress = progressValue
                                    }
                                }
                                DispatchQueue.main.async {
                                    saveProjectSettings()
                                    isProcessing = false
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                if isProcessing {
                    ProgressView(value: progress)
                        .padding()
                }
            }
            .padding()
#if os(iOS)
            .navigationBarTitle("Dataset Corrections", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            #elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Dataset Corrections").font(.headline)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            #endif
        }
    }
    private func updateClassDetails(for className: String) {
        if let yoloClass = projectSettings.classes.first(where: { $0.name == className }) {
            selectedNewClassName = yoloClass.name
            selectedColor = Color(platformColor: yoloClass.color)
        }
    }
    private func saveProjectSettings() {
        let projectSettingsManager = ProjectSettingsManager(settings: projectSettings, directoryURL: folderURL)
        projectSettingsManager.settings = projectSettings
        projectSettingsManager.saveSettings()
    }
    func renameClass(
        folderURL: URL,
        labelStorage: String,
        classes: inout [YOLOClass],
        oldClassName: String,
        newClassName: String,
        newColor: Color,
        progress: @escaping (Double) -> Void
    ) { 
        if let classIndex = classes.firstIndex(where: { $0.name == oldClassName }) {
            classes[classIndex].name = newClassName
            classes[classIndex].color = PlatformColor(newColor)
            saveProjectSettings()
        }
        applyToDatasetWithProgress(folderURL: folderURL, labelStorage: labelStorage, classes: &classes, progress: progress) { _, labels, imgname in
            for index in labels.indices {
                if labels[index].className == oldClassName {
                    labels[index].className = newClassName
                    labels[index].color = newColor
                }
            }
        }
    }
    func resizeBoxes(
        folderURL: URL,
        labelStorage: String,
        classes: inout [YOLOClass],
        scaleFactor: CGFloat,
        mode: String,
        progress: @escaping (Double) -> Void
    ) {
        applyToDatasetWithProgress(folderURL: folderURL, labelStorage: labelStorage, classes: &classes, progress: progress) { fileURL, labels, imgname  in
            for index in labels.indices {
                var box = labels[index].box
                let centerX = box.origin.x + box.width / 2
                let centerY = box.origin.y + box.height / 2
                switch mode {
                case "Relative to box size":
                    box.size.width *= scaleFactor
                    box.size.height *= scaleFactor
                case "Relative to image size":
                    if let image = UIImage(contentsOfFile: fileURL.path) {
                        let imageWidth = CGFloat(image.size.width)
                        let imageHeight = CGFloat(image.size.height)
                        box.size.width += scaleFactor * imageWidth
                        box.size.height += scaleFactor * imageHeight
                    }
                case "Value in pixels":
                    box.size.width += scaleFactor
                    box.size.height += scaleFactor
                default:
                    break
                }
                box.origin.x = centerX - box.width / 2
                box.origin.y = centerY - box.height / 2
                labels[index].box = box
            }
        }
    }
    func shiftBoxes(
        folderURL: URL,
        labelStorage: String,
        classes: inout [YOLOClass],
        shiftX: CGFloat,
        shiftY: CGFloat,
        scaleX: CGFloat,
        scaleY: CGFloat,
        mode: String,
        progress: @escaping (Double) -> Void
    ) {
        applyToDatasetWithProgress(folderURL: folderURL, labelStorage: labelStorage, classes: &classes, progress: progress) { fileURL, labels, imgname  in
            for index in labels.indices {
                var box = labels[index].box
                let originalCenterX = box.origin.x + box.width / 2
                let originalCenterY = box.origin.y + box.height / 2
                switch mode {
                case "Relative to box size":
                    box.origin.x += shiftX * box.width
                    box.origin.y += shiftY * box.height
                case "Relative to image size":
                    if let image = UIImage(contentsOfFile: fileURL.path) {
                        let imageWidth = CGFloat(image.size.width)
                        let imageHeight = CGFloat(image.size.height)
                        box.origin.x += shiftX * imageWidth
                        box.origin.y += shiftY * imageHeight
                    }
                case "Value in pixels":
                    box.origin.x += shiftX
                    box.origin.y += shiftY
                default:
                    break
                }
                box.origin.x = originalCenterX * scaleX - box.width / 2
                box.origin.y = originalCenterY * scaleY - box.height / 2
                labels[index].box = box
            }
        }
    }
}

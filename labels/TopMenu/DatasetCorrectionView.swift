
import SwiftUI
import SwiftUI
import SwiftUI
struct DatasetCorrectionView: View {
    let folderURL: URL
    @Binding var projectSettings: ProjectSettings
    @Binding var image: UIImage?
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
    
    
    @State var objectColors: [Color] = []
    @State var backgroundColors: [Color] = []
    @State var showColorPicker: Bool = false
    
    let shiftModes = ["Relative to box size", "Relative to image size", "Value in pixels"]
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isProcessing {
                    ProgressViewWithEstimation(value: progress)
                        .padding()
                }
                else
                {
                    Section {
                        Text("Rename Class")
                            .font(.headline)
                        HStack {
                            Picker("Select Old Class", selection: $selectedOldClassName) {
                                ForEach(projectSettings.classes, id: \.name) { yoloClass in
                                    Text(yoloClass.name).tag(yoloClass.name)
                                }
                            }
                            .onAppear()
                            {
                                if(selectedOldClassName == "Select class")
                                {
                                    selectedOldClassName = projectSettings.classes.first?.name ?? "Select class"
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
                        VStack
                        {
                            if(image != nil)
                            {
                                Text("Filter with color threshold")
                                    .font(.headline)
                                Button(action:
                                        {
                                    showColorPicker = true
                                }, label:
                                        {
                                    Text("Select colors")
                                })
                                .sheet(isPresented: $showColorPicker) {
                                    ColorPickerView(image: $image, objectColors: $objectColors, backgroundColors: $backgroundColors, presentationMode: $showColorPicker)
                                }
                                if(objectColors.count > 3)
                                {
                                    Button(action:
                                            {
                                        isProcessing = true
                                        DispatchQueue.global(qos: .userInitiated).async {
                                            filterBoxesByColor(
                                                folderURL: folderURL,
                                                labelStorage: projectSettings.labelStorage,
                                                classes: &projectSettings.classes,
                                                colorsObject: objectColors,
                                                colorsBackground: backgroundColors,
                                                progress: { progressValue in
                                                    DispatchQueue.main.async {
                                                        progress = progressValue
                                                    }
                                                })
                                            DispatchQueue.main.async {
                                                isProcessing = false
                                            }
                                        }
                                    }, label:
                                            {
                                        Text("Filter")
                                    })
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
        var seenNames = Set<String>()
        classes = classes.filter { seenNames.insert($0.name).inserted }
        var localClasses = classes
        applyToDatasetWithProgress(folderURL: folderURL, projectSettings: projectSettings, labelStorage: labelStorage, classes: &localClasses, progress: progress, action:
                                    { _, labels, imgname, _, classesIn in
                                        classesIn.lock.lock()
                                        if let classIndex = classesIn.classes.firstIndex(where: { $0.name == oldClassName }) {
                                            classesIn.classes[classIndex].name = newClassName
                                            classesIn.classes[classIndex].color = PlatformColor(newColor)
                                            sortClassesByName(&classesIn.classes)
                                            var newClasses = classesIn.classes
                                            var seenNames = Set<String>()
                                            newClasses = newClasses.filter { seenNames.insert($0.name).inserted }
                                            classesIn.classes = newClasses
                                            DispatchQueue.main.async {
                                                let projectSettingsManager = ProjectSettingsManager(settings: projectSettings, directoryURL: folderURL)
                                                projectSettings.classes = newClasses
                                                projectSettingsManager.settings = projectSettings
                                                projectSettingsManager.saveSettings()
                                            }
                                        }
                                        classesIn.lock.unlock()
                                        for index in labels.indices {
                                            if labels[index].className == oldClassName {
                                                labels[index].className = newClassName
                                                labels[index].color = newColor
                                            }
                                        }
                                    },
                                   actionBefore:
                                    { _, labels, imgname, _, classesIn in
                                        classesIn.lock.lock()
                                        if let classIndex = classesIn.classes.firstIndex(where: { $0.name == newClassName }) {
                                            classesIn.classes[classIndex].name = oldClassName
                                            classesIn.classes[classIndex].color = PlatformColor(newColor)
                                            saveProjectSettings()
                                        }
                                        classesIn.lock.unlock()
                                    }
                                   )
        classes = localClasses
    }
    func filterBoxesByColor(
        folderURL: URL,
        labelStorage: String,
        classes: inout [YOLOClass],
        colorsObject: [Color],
        colorsBackground: [Color],
        progress: @escaping (Double) -> Void
    ) {
        applyToDatasetWithProgress(folderURL: folderURL, projectSettings: projectSettings, labelStorage: labelStorage, classes: &classes, progress: progress) { fileURL, labels, imgname, projectSettings, classesNow    in
            let imageURL = fileURL.appending(path: projectSettings.imageSubdirectory).appending(path: imgname)
            let maskURL = fileURL.appending(path: projectSettings.labelSubdirectory).appending(path: imgname)
            filterBoundingBoxesAvg(
                mainImageURL: imageURL,
                maskImageURL: maskURL,
                labels: &labels,
                objectColors: colorsObject,
                backgroundColors: colorsBackground,
                speedAccuracyFactor: 50, // Higher values = more samples for accuracy
                numberOfLabelsScale: 1.5,
                sharedClasses: classesNow
            )
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
        applyToDatasetWithProgress(folderURL: folderURL, projectSettings: projectSettings, labelStorage: labelStorage, classes: &classes, progress: progress) { fileURL, labels, imgname, _, _   in
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
        applyToDatasetWithProgress(folderURL: folderURL, projectSettings: projectSettings, labelStorage: labelStorage, classes: &classes, progress: progress) { fileURL, labels, imgname, _, _  in
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

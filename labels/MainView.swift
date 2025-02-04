import SwiftUI
struct MainView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var isPortrait: Bool = true
    @State private var isSidebarVisible: Bool = true
    let folderURL: URL
    @Binding var selectedProjectType: DatasetType?
    @Binding var projectSettings: ProjectSettings
    @Binding var projectIsOpenned: Bool
    @State private var images: [URL] = [] 
    @State private var currentIndex: Int = 0 
    @State public var image: UIImage? = nil
    @State public var imageName: String = "None"
    @State private var imagePrevious: UIImage? = nil
    @State private var imageNext: UIImage? = nil
        #if os(macOS)
    @State private var windowSize = CGSize(width: 800, height: 600)
    #else
    @State private var screenSize = UIScreen.main.bounds.size
    #endif
    @State private var frameWidth:CGFloat = 0.0
    @State private var frameHeight:CGFloat = 0.0
    @State private var redraw: Bool = false
    @State public var labels: [ClassLabel] = [] 
    @State public var selectedLabel: UUID?
    @State public var labelFileName:String = "none.csv"
    @State private var isDraggingLabel = false
    @State public var showDatasetLevel = false
    @State private var showTrain = false
    @State private var showConversionMenu = false
    @State private var showProjectSettings = false
    @State private var showGallery = false
    @State private var selectedItem: YOLOClass?
    @State public var speedMove: CGFloat = 0.0005
    private var defaultZoomScale: CGFloat {
        #if os(macOS)
        return 0.25 
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return 0.25 
        case .pad:
            return 0.2 
        default:
            return 0.2 
        }
        #endif
    }
    @State private var zoomScale: CGFloat = 0.2
    @State private var isDrawingEnabled = false
    @State private var projectSettingsManager : ProjectSettingsManager? = nil
    var body: some View {
            NavigationSplitView  {
                if !projectSettings.classes.isEmpty {
                    if(UIDevice.current.userInterfaceIdiom == .phone)
                    {
                        Button(action: {
                            withAnimation {
                                if let previouslySelected = selectedItem {
                                    selectedItem = previouslySelected
                                    projectSettings.selectedClass = previouslySelected
                                } else {
                                    selectedItem = projectSettings.classes.last
                                    projectSettings.selectedClass = projectSettings.classes.last
                                }
                            }
                        }) {
                            Text("Go to Detail View")
                        }
                    }
                }
                sideBar
                    .onAppear { isSidebarVisible = true }
                    .onDisappear { isSidebarVisible = false }
            } detail: {
                ZStack {
                    mainContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .toolbar {
                            leadingToolbar
                            trailingToolbar
                            bottomToolbar
                        }
                }
                .coordinateSpace(name: "CustomSpace")
            }
        
#if os(macOS)
            .onAppear {
                if let window = NSApp.keyWindow {
                    windowSize = window.frame.size
                }
                updateFrameSize(for: windowSize)
                initializeView()
            }
            .onChange(of: windowSize) { newSize in
                updateFrameSize(for: newSize)
                print("Window resized to \(newSize)")
            }
        #else
            .onAppear {
                screenSize = UIScreen.main.bounds.size
                frameWidth = screenSize.width * 4 + 10
                frameHeight = screenSize.height * 3
                if UIDevice.current.orientation.isLandscape {
                    frameWidth = screenSize.width * 4 - 30
                    frameHeight = screenSize.height * 4
                } else if UIDevice.current.orientation.isPortrait {
                    frameWidth = screenSize.width * 4 + 10
                }
                updateOrientation()
                initializeView()
            }
        #endif
            .onChange(of: horizontalSizeClass) { _ in
                updateOrientation()
            }
        }
        private var sideBar: some View {
            SideBar(
                folderURL: folderURL,
                projectSettings: $projectSettings,
                projectSettingsManager: $projectSettingsManager,
                labels: $labels,
                selectedLabel: $selectedLabel,
                saveSettings: saveSettings,
                removeLabel: removeLabel,
                deleteLabel: deleteLabel
            )
        }
        private var mainContent: some View {
            VStack {
                if let image = image {
                    imageDisplay
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    noImageLoadedView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        private var imageDisplay: some View {
                #if os(macOS)
                return ZoomableScrollView(
                    zoomScale: $zoomScale,
                    isDrawingEnabled: $isDrawingEnabled,
                    isScrollDisabled: $isDraggingLabel,
                    defaultZoomScale: defaultZoomScale
                ) {
                    BoxLabelingView(
                        folderURL: folderURL,
                        currentImage: $imageName,
                        image: $image,
                        labels: $labels,
                        projectSettings: $projectSettings,
                        labelFileName: $labelFileName,
                        selectedLabel: $selectedLabel,
                        zoomScale: $zoomScale,
                        defaultZoomScale: defaultZoomScale,
                        isDrawingEnabled: $isDrawingEnabled,
                        isDragging: $isDraggingLabel,
                        selectedItem: $selectedItem
                    )
                    .frame(width: frameWidth, height: frameHeight)
                }
                .id(redraw)
                .onAppear {
                    zoomScale = defaultZoomScale
                    redraw.toggle()
                }
                .frame(maxWidth: windowSize.width - 200, maxHeight: windowSize.height - 100)
                .onChange(of: windowSize) { newSize in
                    recenterContent(for: newSize)
                }
                .onChange(of: isSidebarVisible) { visible in
                    print("Sidebar is now \(visible ? "visible" : "hidden")")
                    let sidebarWidth: CGFloat = visible ? 0 : 370
                    let adjustedWidth = windowSize.width + sidebarWidth
                    windowSize = CGSize(width: adjustedWidth, height: windowSize.height)
                    updateFrameSize(for: windowSize)
                    print("\(windowSize) \(frameWidth)x\(frameHeight) update sidebar")
                    redraw.toggle() 
                }
                #else
                return ZoomableScrollView(
                    zoomScale: $zoomScale,
                    isDrawingEnabled: $isDrawingEnabled,
                    isScrollDisabled: $isDraggingLabel,
                    onSwitchView: { direction in
                        if direction == .left {
                            loadPreviousImage()
                        } else if direction == .right {
                            loadNextImage()
                        }
                    },
                    defaultZoomScale: defaultZoomScale
                ) {
                    BoxLabelingView(
                        folderURL: folderURL,
                        currentImage: $imageName,
                        image: $image,
                        labels: $labels,
                        projectSettings: $projectSettings,
                        labelFileName: $labelFileName,
                        selectedLabel: $selectedLabel,
                        zoomScale: $zoomScale,
                        defaultZoomScale: defaultZoomScale,
                        isDrawingEnabled: $isDrawingEnabled,
                        isDragging: $isDraggingLabel,
                        selectedItem: $selectedItem
                    )
                    .frame(width: frameWidth, height: frameHeight)
                }
                .id(redraw)
                .onAppear {
                    zoomScale = defaultZoomScale
                    print("\(screenSize) \(frameWidth)x\(frameHeight) startt")
                    redraw.toggle()
                }
                .onChange(of: isSidebarVisible) { visible in
                    print("Sidebar is now \(visible ? "visible" : "hidden")")
                    let sidebarWidth: CGFloat = visible ? 0: 370
                    let adjustedWidth = UIScreen.main.bounds.width + sidebarWidth
                    screenSize = CGSize(width: adjustedWidth, height: UIScreen.main.bounds.height)
                    frameWidth = UIScreen.main.bounds.width * 4 + 10
                    frameHeight = screenSize.height * 3
                    if UIDevice.current.orientation.isLandscape {
                        frameWidth = screenSize.width * 4 - 30
                        frameHeight = screenSize.height * 4
                    } else if UIDevice.current.orientation.isPortrait {
                        frameWidth = UIScreen.main.bounds.width * 5 + 10
                        frameHeight = screenSize.height * 4
                    }
                    recenterContent(for: screenSize)
                    print("\(screenSize) \(frameWidth)x\(frameHeight) update sidebar")
                    redraw.toggle() 
                }
                .onChange(of: isPortrait) {
                    screenSize = UIScreen.main.bounds.size
                    frameWidth = screenSize.width * 4 + 10
                    frameHeight = screenSize.height * 4
                    recenterContent(for: screenSize)
                    print("\(screenSize) \(frameWidth)x\(frameHeight) update rotate")
                    redraw.toggle()
                }
                #endif
        }
        private func updateFrameSize(for size: CGSize) {
            frameWidth = size.width * 4 + 10
            frameHeight = size.height * 3
            if size.width > size.height { 
                frameWidth = size.width * 4 - 30
                frameHeight = size.height * 4
            } else { 
                frameWidth = size.width * 5 + 10
                frameHeight = size.height * 4
            }
        }
        private func recenterContent(for newSize: CGSize) {
            DispatchQueue.main.async {
                let centerOffsetX = max(0, (newSize.width * 4 - newSize.width) / 2)
                let centerOffsetY = max(0, (newSize.height * 4 - newSize.height) / 2)
                zoomScale = defaultZoomScale
            }
        }
        private var noImageLoadedView: some View {
            Text("No image loaded")
                .font(.headline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        private var bottomToolbar: some ToolbarContent {
            #if os(iOS)
            ToolbarItemGroup(placement: .bottomBar) {
                toolbarContent
            }
            #elseif os(macOS)
            ToolbarItemGroup(placement: .automatic) {
                toolbarContent
            }
            #endif
        }
        private var leadingToolbar: some ToolbarContent {
            #if os(iOS)
            ToolbarItemGroup(placement: .topBarLeading) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    compactToolbarContent 
                } else {
                    leadingToolbarContent 
                }
            }
            #elseif os(macOS)
            ToolbarItemGroup(placement: .navigation) {
                toolbarContent
                Spacer()
                leadingToolbarContent
                trailingToolbarContent
            }
            #endif
        }
        private var trailingToolbar: some ToolbarContent {
            #if os(iOS)
            ToolbarItemGroup(placement: .topBarTrailing) {
                trailingToolbarContent
                    .sheet(isPresented: $showProjectSettings) {
                        CreateProjectSettingsView(datasetType: projectSettings.datasetType, folderUrl: folderURL, name: projectSettings.name, description: projectSettings.description, icon: projectSettings.icon ?? "", hashtags: projectSettings.hashtags.joined(separator: ", "), labelStorage: getLabelStorage(byName:projectSettings.labelStorage), editing: true, projectSettings: $projectSettings, showGetData: $showProjectSettings)
                    }
                    .sheet(isPresented: $showDatasetLevel, onDismiss: {
                        loadImage(at: currentIndex)
                    }) {
                        DatasetCorrectionView(folderURL: folderURL, projectSettings: $projectSettings, image: $image)
                    }
                    .sheet(isPresented: $showConversionMenu, onDismiss: {
                        loadImage(at: currentIndex)
                    }) {
                        ConversionMenu(
                            currentFormat: projectSettings.labelStorage,
                            datasetType: projectSettings.datasetType,
                            folderURL: folderURL,
                            projectSettings: $projectSettings,
                            labels: $labels,
                            imageName: imageName
                        )
                    }
                    .sheet(isPresented: $showGallery) {
                        ImageGalleryView(images: $images, currentIndex: $currentIndex, image: $image, imageName: $imageName, loadImage: loadImage, onCancel: { showGallery = false })
                    }
                    NavigationLink(
                        destination: TrainingView(datasetPath: folderURL, show: $showTrain),
                        isActive: $showTrain,
                        label: { EmptyView() }
                    )
                    .hidden()
            }
            #elseif os(macOS)
            ToolbarItemGroup(placement: .automatic) {
            }
            #endif
        }
        private var toolbarContent: some View {
            HStack {
                if(UIDevice.current.userInterfaceIdiom == .phone)
                {
                    Button(action: loadPreviousImage) {
                        Image(systemName: "chevron.backward")
                    }
                    .padding(.trailing, 45)
                    .disabled(currentIndex <= 0)
                    Spacer()
                    drawingButton
                    Spacer()
                    zoomMenu
                    Button(action: loadNextImage) {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(currentIndex >= images.count - 1)
                }
                else
                {
                    
                    Button(action: loadPreviousImage) {
                        Text("Previous")
                    }
                    .disabled(currentIndex <= 0)
                    Spacer()
                    imageInfoToolbarContent
                    Spacer()
                    drawingButton
                    ZoomButtons(zoomScale: $zoomScale, defaultZoomScale: defaultZoomScale)
                    Button(action: loadNextImage) {
                        Text("Next")
                    }
                    .disabled(currentIndex >= images.count - 1)
                }
            }
        }
        private var zoomMenu: some View {
            Menu {
                ZoomButtons(zoomScale: $zoomScale, defaultZoomScale: defaultZoomScale)
            }label: {
                Label("", systemImage: "plus.magnifyingglass")
            }
        }
        private var imageInfoToolbarContent: some View {
            Group {
                HStack {
                    Text("\(currentIndex + 1) / \(images.count)")
                        .frame(width: 70)
                    Text((imageName as NSString).deletingPathExtension)
                        .frame(width: 120)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.trailing, 10)
                .onTapGesture {
                    showGallery = true
                }
            }
        }
        private var compactToolbarContent: some View {
            HStack
            {
                if selectedLabel == nil {
                    Menu {
                        datasetManagementMenu
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
//                else {
//                    movementButtons
//                }
            }
        }
        private var leadingToolbarContent: some View {
            Group {
                if selectedLabel == nil {
                    datasetManagementMenu
                } else {
                    movementButtons
                }
            }
        }
        private var trailingToolbarContent: some View {
            Group {
                if selectedLabel != nil {
                    if(UIDevice.current.userInterfaceIdiom == .phone)
                    {
                        movementButtons
                    }
                    resizeButtons
                    classPickerButton
                } else {
                    if(UIDevice.current.userInterfaceIdiom == .phone)
                    {
//                        imageInfoToolbarContent
                        Button(action: closeProject) {
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                        }
                    }
                    else
                    {
                        Button(action: closeProject) {
                            Text("Close")
                        }
                    }
                }
            }
        }
        private var datasetManagementMenu: some View {
            Group {
                Button("Project Settings"){
                    showProjectSettings = true
                }
                Button("Dataset Changes") {
                    showDatasetLevel = true
                }
                Button("Convert Format") {
                    showConversionMenu = true
                }
                Button("Train helper model") {
                    showTrain = true
                }
            }
        }
        private var drawingButton: some View {
            Button(action: { isDrawingEnabled.toggle() }) {
                Image(systemName: "pencil")
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(isDrawingEnabled ? Color.green.opacity(0.8) : Color.gray.opacity(0.2))
                    .foregroundColor(isDrawingEnabled ? Color.green : Color.gray.opacity(0.6))
                    .cornerRadius(10)
            }
        }
    private func handleKeyboardEvent(_ notification: Notification) {
        guard let keyCode = notification.userInfo?["keyCode"] as? UInt16 else { return }
        switch keyCode {
        case 123: 
            moveLabel(dx: -1.0*speedMove, dy: 0)
        case 124: 
            moveLabel(dx: speedMove, dy: 0)
        case 125: 
            moveLabel(dx: 0, dy: speedMove)
        case 126: 
            moveLabel(dx: 0, dy: -1.0*speedMove)
        case 24: 
            resizeLabel(scaleFactor: 1.0+speedMove*2.0)
        case 27: 
            resizeLabel(scaleFactor: 1.0-speedMove*2.0)
        default:
            break
        }
    }
    func saveSettings()
    {
        if(projectSettingsManager == nil)
        {
            projectSettingsManager = ProjectSettingsManager(settings: projectSettings, directoryURL: folderURL)
        }
        projectSettingsManager!.settings = projectSettings
        projectSettingsManager!.saveSettings()
    }
    func removeLabel(_ label: ClassLabel) {
        if let index = labels.firstIndex(where: { $0.id == label.id }) {
            labels.remove(at: index)
        }
        let labelStorageFormat = projectSettings.labelStorage
        saveLabelsInFormat(
            labelStorage: labelStorageFormat,
            filePath: folderURL, labelFileName: labelFileName,
            imageName: imageName,
            labels: labels,
            classes: &projectSettings.classes
        )
    }
    func deleteLabel(at offsets: IndexSet) {
        labels.remove(atOffsets: offsets)
        let labelStorageFormat = projectSettings.labelStorage
        saveLabelsInFormat(
            labelStorage: labelStorageFormat,
            filePath: folderURL, labelFileName: labelFileName,
            imageName: imageName,
            labels: labels,
            classes: &projectSettings.classes
        )
    }
    func checkAndCreateLabelsFile() {
        let labelsFileURL = folderURL.appendingPathComponent("labels.json")
        if !FileManager.default.fileExists(atPath: labelsFileURL.path) {
            let initialData: [String: [ClassLabel]] = [:] 
            do {
                let data = try JSONEncoder().encode(initialData)
                try data.write(to: labelsFileURL, options: .atomic)
                print("✅ Created new labels.json file.")
            } catch {
                print("❌ Failed to create labels.json file: \(error)")
            }
        }
    }
    private func loadLabels() {
        let labelsFileURL = folderURL.appending(path: projectSettings.labelSubdirectory)
        let labelStorageFormat = projectSettings.labelStorage
        (labels, labelFileName) = loadLabelsFromFormat(
            labelStorage: labelStorageFormat,
            filePath: labelsFileURL,
            imageName: imageName,
            classes: &projectSettings.classes 
        )
    }
    func initializeView() {
        checkAndCreateLabelsFile()
        loadImages()
        loadInitialImage()
    }
    func loadImages() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderURL.appendingPathComponent(projectSettings.imageSubdirectory), includingPropertiesForKeys: nil)
            images = files.filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "png"  || $0.pathExtension.lowercased() == "jpeg"  || $0.pathExtension.lowercased() == "heic" }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        } catch {
            print("❌ Failed to load images: \(error)")
        }
    }
    func loadInitialImage() {
        guard !images.isEmpty else { return }
        currentIndex = 0
        loadImage(at: currentIndex)
    }
    func saveAll()
    {
        saveSettings()
        let labelStorageFormat = projectSettings.labelStorage
        saveLabelsInFormat(
            labelStorage: labelStorageFormat,
            filePath: folderURL, labelFileName: labelFileName,
            imageName: imageName,
            labels: labels,
            classes: &projectSettings.classes
        )
    }
    func loadImage(at index: Int) {
        guard index >= 0 && index < images.count else { return }
        currentIndex = index
        imageName = images[currentIndex].lastPathComponent
        image = UIImage(contentsOfFile: images[index].path)
        imagePrevious = index > 0 ? UIImage(contentsOfFile: images[index - 1].path) : nil
        imageNext = index < images.count - 1 ? UIImage(contentsOfFile: images[index + 1].path) : nil
        loadLabels()
        saveSettings()
    }
    func loadPreviousImage() {
        selectedLabel = nil
        loadImage(at: currentIndex - 1)
    }
    func loadNextImage() {
        selectedLabel = nil
        loadImage(at: currentIndex + 1)
    }
    func resizeLabel(scaleFactor: CGFloat) {
        guard let selected = selectedLabel,
              let index = labels.firstIndex(where: { $0.id == selected }) else { return }
        var box = labels[index].box
        let centerX = box.midX
        let centerY = box.midY
        box.size.width *= scaleFactor
        box.size.height *= scaleFactor
        box.origin.x = centerX - box.size.width / 2
        box.origin.y = centerY - box.size.height / 2
        labels[index].box = box
        let labelStorageFormat = projectSettings.labelStorage
        saveLabelsInFormat(
            labelStorage: labelStorageFormat,
            filePath: folderURL, labelFileName: labelFileName,
            imageName: imageName,
            labels: labels,
            classes: &projectSettings.classes
        )
    }
    func changeClass(to yoloClass: YOLOClass) {
        guard let selected = selectedLabel,
              let index = labels.firstIndex(where: { $0.id == selected }) else { return }
        labels[index].className = yoloClass.name
        labels[index].color = Color(platformColor: yoloClass.color)
        saveAll()
    }
    func closeProject()
    {
        projectSettings = ProjectSettings(name: "", description: "", hashtags: [], datasetType: .none, labelStorage: "", creationDate: Date.now, lastModifiedDate: Date.now, directoryPath: "", imageSubdirectory:"", labelSubdirectory:"", classes: [])
        projectIsOpenned = false
        selectedProjectType = nil
    }
    private func updateOrientation() {
        if UIDevice.current.orientation.isLandscape {
            isPortrait = false
        } else if UIDevice.current.orientation.isPortrait {
            isPortrait = true
        }
        print("Orientation: \(isPortrait ? "Portrait" : "Landscape")")
    }
}
extension Color {
    static var random: Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

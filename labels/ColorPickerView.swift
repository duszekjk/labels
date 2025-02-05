import SwiftUI

struct ColorPickerView: View {
    let folderURL: URL
    @Binding var currentImage: String
    @Binding var image: UIImage?
    @Binding var objectColors: [Color]
    @Binding var backgroundColors: [Color]
    @Binding var presentationMode: Bool
    @Binding var labelsStart: [ClassLabel]
    @Binding var projectSettings: ProjectSettings
    @Binding var labelStrength: Double
    @Binding var filterMethod: String
    var onSwitchView: ((Direction) -> Void)
    var filter: (() -> Void)
    @State var labels: [ClassLabel] = []
    
    @State private var isSelectingObjectColors = true
    @State private var isAdjusting = false
    @State private var isSwitchingNext = true
    @State private var selectedColors: [Color] = []
    
    var body: some View {
        ZStack {
            if isSwitchingNext {
                Text(isSelectingObjectColors ? "Select 20 colors of Object" : (isAdjusting ? "Adjust strength and colors" : "Select 20 Background Colors"))
                    .font(.title)
                    .onAppear() {
                        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
                            DispatchQueue.main.async {
                                isSwitchingNext = false
                            }
                        }
                    }
            } else {
                VStack {
                    if(image != nil)
                    {
                        GeometryReader { geometry in
                            let containerSize = geometry.size
                            let imageAspectRatio = image!.size.width / image!.size.height
                            let containerAspectRatio = containerSize.width / containerSize.height
                            let isImageWide = imageAspectRatio > containerAspectRatio
                            let imageWidth = isImageWide ? containerSize.width : containerSize.height * imageAspectRatio
                            let imageHeight = isImageWide ? containerSize.width / imageAspectRatio : containerSize.height
                            let imageOffsetX = (containerSize.width - imageWidth) / 2
                            let imageOffsetY = 0.0
                            
                            Image(uiImage: image!)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(15)
                                .gesture(DragGesture(minimumDistance: 20)
                                    .onEnded { value in
                                        if value.translation.width < 0 {
                                            image = nil
                                            onSwitchView(.right)
                                            reloadLabels()
                                        } else if value.translation.width > 0 {
                                            image = nil
                                            onSwitchView(.left)
                                            reloadLabels()
                                        }
                                    }
                                )
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        if(!isAdjusting)
                                        {
                                            let location = value.location
                                            let convertedLocation = CGPoint(
                                                x: location.x * (image!.size.width / geometry.size.width) + imageOffsetX,
                                                y: location.y * (image!.size.width / geometry.size.width) + imageOffsetY
                                            )
                                            
                                            if let pickedColor = pickColor(from: image!, at: convertedLocation) {
                                                
                                                if isSelectingObjectColors {
                                                    objectColors.append(pickedColor)
                                                } else {
                                                    backgroundColors.append(pickedColor)
                                                }
                                                if objectColors.count == 20 && isSelectingObjectColors {
                                                    isSelectingObjectColors = false
                                                    isSwitchingNext = true
                                                }
                                                if backgroundColors.count == 20 && !isSelectingObjectColors
                                                {
                                                    isAdjusting = true
//                                                    isSwitchingNext = true
                                                }
                                            }
                                        }
                                    }
                                )
                            
                            ForEach(labels) { labelBox in
                                let scaleX = imageWidth / image!.size.width
                                let scaleY = imageHeight / image!.size.height
                                let adjustedBox = CGRect(
                                    x: (labelBox.box.origin.x * scaleX) + imageOffsetX,
                                    y: (labelBox.box.origin.y * scaleY) + imageOffsetY,
                                    width: labelBox.box.width * scaleX,
                                    height: labelBox.box.height * scaleY
                                )
                                
                                Rectangle()
                                    .stroke(labelBox.color.opacity(0.8), lineWidth: 2)
                                    .background(Color.white.opacity(0.05))
                                    .frame(width: adjustedBox.width, height: adjustedBox.height)
                                    .position(x: adjustedBox.midX, y: adjustedBox.midY)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                bottomMenu
            }
        }
        .background(Color(platformColor: .systemGray3))
        .frame(minHeight: 900)
        
    }
    var adjusting : some View
    {
        HStack
        {
            if(!isAdjusting)
            {
                Text("Color selection mode")
                Button(action:
                        {
                    isAdjusting = true
//                    isSwitchingNext = true
                }, label:
                        {
                    Text("Switch to adjusting")
                })
            }
            else
            {
                Slider(value: $labelStrength, in: 50...250, step: 10) { _ in
                    labelStrength = labelStrength.rounded()
                    reloadLabels()
                }
                Text(labelStrength.description)
            }
        }
        .opacity(0.9)
        .scaleEffect(0.9)
        .padding(.top, -10)
    }
    var bottomMenu: some View
    {
        VStack {
            Spacer()
            VStack {
                topMenu
                List {

                    HStack {
                        Picker("Filter Method", selection: $filterMethod) {
                            ForEach(filterMethods, id: \.self) { method in
                                Text(method).tag(method)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    adjusting
                        .listRowBackground((isAdjusting) ? Color.blue.opacity(0.3) : Color.clear)

                    ColorSelectionView(
                        title: "Object",
                        colors: $objectColors,
                        switchList: {
                            isSelectingObjectColors = true
                            isAdjusting = false
                        }
                    )
                    .listRowBackground((isSelectingObjectColors && !isAdjusting) ? Color.blue.opacity(0.3) : Color.clear)

                    ColorSelectionView(
                        title: "Background",
                        colors: $backgroundColors,
                        switchList: {
                            isSelectingObjectColors = false
                            isAdjusting = false
                        }
                    )
                    .listRowBackground((!isSelectingObjectColors && !isAdjusting) ? Color.blue.opacity(0.3) : Color.clear)
                }
                .listStyle(PlainListStyle()) // Ensures full-row selection works
//                .padding(.top, -10)
                .padding(.bottom, 10)
                .frame(height: 230)
                .opacity(0.7)


            }
            .background(.white.shadow(.drop(color: .black, radius: 5)))
        }
        .onChange(of: backgroundColors) { oldValue, newValue in
            reloadLabels()
        }
        .onChange(of: filterMethod)
        {
            reloadLabels()
        }
    }
    var topMenu : some View
    {
        HStack {
            Button(action: {
                objectColors = []
                backgroundColors = []
                selectedColors = []
                isSelectingObjectColors = true
                isAdjusting = false
                isSwitchingNext = true
            }) {
                Text("Clear")
                    .foregroundStyle(.red)
            }
            Spacer()
            Text(isSelectingObjectColors ? "Select 20 colors of Object" : (isAdjusting ? "Adjust strength and colors" : "Select 20 Background Colors"))
                .font(.headline)
                .opacity(0.9)
            Spacer()
            Button(action: {
                presentationMode = false
                filter()
            }) {
                Text("Filter")
            }
        }
        .padding(10)
        .background(.white)
        .opacity(0.95)
        .padding(.bottom, -9)
        .onAppear()
        {
            labels = labelsStart
            if(objectColors.count >= 20)
            {
                isSelectingObjectColors = false
                
                if(backgroundColors.count >= 20)
                {
                    isSelectingObjectColors = false
                    isAdjusting = true
                    reloadLabels()
                }
//                isSwitchingNext = true
            }
        }
    }
    func reloadLabels()
    {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1)
        {
            labels = labelsStart
            
            DispatchQueue.main.asyncAfter(deadline: .now()+0.15)
            {
                if(objectColors.count > 3 && backgroundColors.count > 3)
                {
                    let imageURL = folderURL.appending(path: projectSettings.imageSubdirectory).appending(path: currentImage)
                    let maskURL = folderURL.appending(path: projectSettings.labelSubdirectory).appending(path: currentImage)
                    let classesNow = SharedClasses(classes: projectSettings.classes)
                    filterBoundingBoxes(
                        mainImageURL: imageURL,
                        maskImageURL: maskURL,
                        labels: &labels,
                        objectColors: objectColors,
                        backgroundColors: backgroundColors,
                        speedAccuracyFactor: 50, // Higher values = more samples for accuracy
                        numberOfLabelsScale: labelStrength,
                        sharedClasses: classesNow,
                        method: filterMethod
                    )
                }
            }
        }
    }
    func pickColor(from image: UIImage, at location: CGPoint) -> Color? {
        guard let cgImage = image.cgImage else { return nil }
        let x = Int(location.x)
        let y = Int(location.y)
        print("getting color at \(x) x \(y) from image \(image.size.width) \(image.size.height)")
        guard let pixelColor = cgImage.color(atX: x, y: y) else { return nil }
        return Color(pixelColor)
    }
}

extension CGImage {
    func color(atX x: Int, y: Int) -> UIColor? {
        guard let dataProvider = self.dataProvider,
              let data = dataProvider.data else { return nil }
        print("iamgeOK")
        let pixelData = CFDataGetBytePtr(data)
        let bytesPerPixel = 4
        let index = (y * self.width + x) * bytesPerPixel
        guard index + 3 < CFDataGetLength(data) else { return nil }
        print("dataOK")
        guard let pixelData = pixelData else { return nil }
        print("pixeldataOK")
        return UIColor(
            red: CGFloat(pixelData[index]) / 255.0,
            green: CGFloat(pixelData[index + 1]) / 255.0,
            blue: CGFloat(pixelData[index + 2]) / 255.0,
            alpha: 1.0
        )
    }
}

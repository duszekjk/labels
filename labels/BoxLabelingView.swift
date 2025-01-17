import SwiftUI
struct BoxLabelingView: View {
    let folderURL: URL
    @Binding var currentImage: String
    @Binding var image: UIImage?
    @Binding var labels: [ClassLabel]
    @Binding var projectSettings: ProjectSettings
    @Binding var labelFileName: String
    @Binding var selectedLabel: UUID?
    @Binding var zoomScale:CGFloat
    var defaultZoomScale: CGFloat
    @Binding var isDrawingEnabled: Bool
    @Binding var isDragging: Bool
    @Binding var selectedItem: YOLOClass?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero
    @State private var currentDrawing: CGRect? = nil 
    @State private var startPoint: CGPoint? = nil
    @State private var activeGesture: ActiveGesture = .none 
    @State private var liveBox: CGRect? = nil 
    enum ActiveGesture {
        case zoom, pan, draw, none
    }
    var body: some View {
        ZStack {
            if let image = image {
                GeometryReader { geometry in
                    let containerSize = geometry.size
                    let imageAspectRatio = image.size.width / image.size.height
                    let containerAspectRatio = containerSize.width / containerSize.height
                    let isImageWide = imageAspectRatio > containerAspectRatio
                    let imageWidth = isImageWide ? containerSize.width : containerSize.height * imageAspectRatio
                    let imageHeight = isImageWide ? containerSize.width / imageAspectRatio : containerSize.height
                    let imageOffsetX = (containerSize.width - imageWidth) / 2
                    let imageOffsetY = (containerSize.height - imageHeight) / 2
                    let imageFrame = CGRect(
                        x: imageOffsetX,
                        y: imageOffsetY,
                        width: imageWidth,
                        height: imageHeight
                    )
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageWidth, height: imageHeight)
                        .position(x: containerSize.width / 2, y: containerSize.height / 2)
                    if let currentDrawing = currentDrawing {
                        let scaleX = imageWidth / image.size.width
                        let scaleY = imageHeight / image.size.height
                        Rectangle()
                            .stroke(Color.red, lineWidth: 2 / zoomScale)
                            .frame(
                                width: (currentDrawing.width ),
                                height: (currentDrawing.height )
                            )
                            .position(
                                x: ((currentDrawing.origin.x + currentDrawing.width / 2) ),
                                y: ((currentDrawing.origin.y + currentDrawing.height / 2)) + imageOffsetY
                            )
                    }
                    if let liveBox = liveBox {
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: liveBox.width, height: liveBox.height)
                            .position(x: liveBox.midX, y: liveBox.midY)
                    }
                    PencilDrawingView(useMouseAsPencil: $isDrawingEnabled) { touch, view in
                        handlePencilDrawing(touch: touch, in: view)
                    }
                    .allowsHitTesting(true)
                    .simultaneousGesture(
                        TapGesture(count: 2) 
                            .onEnded {
                                selectedLabel = nil 
                            }
                        )
                    .simultaneousGesture(
                        TapGesture(count: 3)
                            .onEnded {
                                zoomScale = defaultZoomScale
                            }
                    )
                    ForEach(labels) { labelBox in
                        let scaleX = imageWidth / image.size.width
                        let scaleY = imageHeight / image.size.height
                        let adjustedBox = CGRect(
                            x: (labelBox.box.origin.x * scaleX) + imageOffsetX,
                            y: (labelBox.box.origin.y * scaleY) + imageOffsetY,
                            width: labelBox.box.width * scaleX,
                            height: labelBox.box.height * scaleY
                        )
                        let isSelected = selectedLabel == labelBox.id
                        if isSelected {
                            Rectangle()
                                .stroke(Color.black, lineWidth: 8 / zoomScale)
                                .blur(radius: 12)
                                .frame(width: adjustedBox.width, height: adjustedBox.height)
                                .position(x: adjustedBox.midX, y: adjustedBox.midY)
                                .opacity(0.8)
                        }
                        Rectangle()
                            .stroke(isSelected ? labelBox.color : labelBox.color.opacity(0.8), lineWidth: (isSelected ? 3 : 2) / zoomScale)
                            .background(Color.white.opacity(0.05))
                            .frame(width: adjustedBox.width, height: adjustedBox.height)
                            .position(x: adjustedBox.midX, y: adjustedBox.midY)
                            .allowsHitTesting(true)
                            .onTapGesture {
                                if selectedLabel == labelBox.id {
                                    selectedLabel = nil
                                } else {
                                    selectedLabel = labelBox.id
                                }
                            }
                    }
                    if let selectedLabelBox = labels.first(where: { $0.id == selectedLabel }), let selectedLabelIndex = labels.firstIndex(where: { $0.id == selectedLabel }) {
                        let scaleX = imageWidth / image.size.width
                        let scaleY = imageHeight / image.size.height
                        let adjustedBox = CGRect(
                            x: (selectedLabelBox.box.origin.x * scaleX) + imageOffsetX,
                            y: (selectedLabelBox.box.origin.y * scaleY) + imageOffsetY,
                            width: selectedLabelBox.box.width * scaleX,
                            height: selectedLabelBox.box.height * scaleY
                        )
                        Rectangle()
                            .stroke(selectedLabelBox.color, lineWidth: 3 / zoomScale)
                            .background(Color.white.opacity(0.05))
                            .frame(width: adjustedBox.width, height: adjustedBox.height)
                            .position(x: adjustedBox.midX, y: adjustedBox.midY)
                            .allowsHitTesting(true)
                            .onTapGesture {
                                if selectedLabel == selectedLabelBox.id {
                                    selectedLabel = nil
                                } else {
                                    selectedLabel = selectedLabelBox.id
                                }
                            }
                        let buttonSize: CGFloat = 40 / zoomScale 
                        let buttonOffset: CGFloat = 20 / zoomScale 
                        let buttonY = adjustedBox.minY - buttonOffset - buttonSize / 2
                        let isOutsideTop = buttonY < 0 
                        Button(action: {
                            print("Move button tapped for label \(selectedLabelBox.id)")
                        }) {
                            ZStack
                            {
                                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(buttonSize*0.09)
                                    .frame(width: buttonSize*1.02, height: buttonSize*1.02)
                                    .foregroundColor(.black)
                                    .shadow(radius: 5)
                                    .background(Color.white.opacity(0.6))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(buttonSize*0.1)
                                    .frame(width: buttonSize, height: buttonSize)
                                    .foregroundColor(selectedLabelBox.color.opacity(0.8))
                                    .shadow(radius: 5)
                            }
                        }
                        .position(
                            x: adjustedBox.midX,
                            y: isOutsideTop ? (adjustedBox.maxY + buttonOffset + buttonSize / 2) : buttonY
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    if let selectedLabelIndex = labels.firstIndex(where: { $0.id == selectedLabel }) {
                                        handleAnchorMovement(
                                            touch: value.location,
                                            for: selectedLabelIndex,
                                            imageWidth: imageWidth,
                                            imageHeight: imageHeight,
                                            imageOffsetX: imageOffsetX,
                                            imageOffsetY: imageOffsetY,
                                            buttonOffset: buttonOffset+(buttonSize/2.0),
                                            image: image
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    saveLabels()
                                    isDragging = false
                                }
                        )
                        let cornerSize: CGFloat = 40/zoomScale
                                let corners = [
                                    CGPoint(x: adjustedBox.minX-cornerSize/2.0, y: adjustedBox.minY-cornerSize/2.0), 
                                    CGPoint(x: adjustedBox.maxX+cornerSize/2.0, y: adjustedBox.minY-cornerSize/2.0), 
                                    CGPoint(x: adjustedBox.minX-cornerSize/2.0, y: adjustedBox.maxY+cornerSize/2.0), 
                                    CGPoint(x: adjustedBox.maxX+cornerSize/2.0, y: adjustedBox.maxY+cornerSize/2.0)  
                                ]
                                ForEach(0..<4) { index in
                                    let cornerPosition = corners[index]
                                    let arrowRotation: Angle = {
                                        switch index {
                                        case 0: return .degrees(-135) 
                                        case 1: return .degrees(-45)  
                                        case 2: return .degrees(135)  
                                        case 3: return .degrees(45)   
                                        default: return .degrees(0)
                                        }
                                    }()
                                    Button(action: {
                                    }) {
                                        ZStack {
                                            Image(systemName: "arrow.forward")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(cornerSize * 0.09)
                                                .frame(width: cornerSize * 1.02, height: cornerSize * 1.02)
                                                .foregroundColor(.black)
                                                .shadow(radius: 5)
                                                .background(Color.white.opacity(0.6))
                                                .clipShape(Circle())
                                                .shadow(radius: 5)
                                                .rotationEffect(arrowRotation)
                                            Image(systemName: "arrow.forward")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(cornerSize * 0.1)
                                                .frame(width: cornerSize, height: cornerSize)
                                                .foregroundColor(selectedLabelBox.color.opacity(0.8))
                                                .shadow(radius: 5)
                                                .rotationEffect(arrowRotation)
                                        }
                                    }
                                    .position(cornerPosition)
                                    .simultaneousGesture(
                                        DragGesture()
                                            .onChanged { value in
                                                isDragging = true
                                                if let selectedLabelIndex = labels.firstIndex(where: { $0.id == selectedLabel }) {
                                                    handleResizeAnchorMovement(
                                                        touch: value.location,
                                                        for: selectedLabelIndex,
                                                        corner: index,
                                                        imageWidth: imageWidth,
                                                        imageHeight: imageHeight,
                                                        imageOffsetX: imageOffsetX,
                                                        imageOffsetY: imageOffsetY,
                                                        buttonOffsetX: (cornerSize/4.0),
                                                        buttonOffsetY: cornerSize/4.0 ,
                                                        image: image
                                                    )
                                                }
                                            }
                                            .onEnded { _ in
                                                saveLabels()
                                                isDragging = false
                                            }
                                    )
                                }
                    }
                }
            }
        }
        .onAppear()
        {
            if(projectSettings.selectedClass != nil)
            {
                selectedItem = projectSettings.selectedClass
            }
        }
    }
    private func handleResizeAnchorMovement(
        touch: CGPoint,
        for labelIndex: Int,
        corner: Int,
        imageWidth: CGFloat,
        imageHeight: CGFloat,
        imageOffsetX: CGFloat,
        imageOffsetY: CGFloat,
        buttonOffsetX: CGFloat,
        buttonOffsetY: CGFloat,
        image: UIImage
    ) {
        guard labelIndex >= 0 && labelIndex < labels.count else { return }
        let imageSize = image.size
        let scaleX = imageWidth / imageSize.width
        let scaleY = imageHeight / imageSize.height
        let adjustedX = (touch.x - imageOffsetX) / scaleX
        let adjustedY = (touch.y - imageOffsetY) / scaleY
        var box = labels[labelIndex].box
        switch corner {
        case 0: 
            let newWidth = max(10, box.maxX - adjustedX)  - buttonOffsetX 
            let newHeight = max(10, box.maxY - adjustedY) - buttonOffsetY
            let newX = box.maxX - newWidth
            let newY = box.maxY - newHeight
            if newX >= 0, newY >= 0 { 
                box.origin.x = newX
                box.origin.y = newY
                box.size.width = newWidth
                box.size.height = newHeight
            }
        case 1: 
            let newWidth = max(10, adjustedX - box.minX) - buttonOffsetX
            let newHeight = max(10, box.maxY - adjustedY) - buttonOffsetY
            let newY = box.maxY - newHeight
            if newWidth + box.minX <= imageSize.width, newY >= 0 { 
                box.size.width = newWidth
                box.origin.y = newY
                box.size.height = newHeight
            }
        case 2: 
            let newWidth = max(10, box.maxX - adjustedX) - buttonOffsetX
            let newHeight = max(10, adjustedY - box.minY) - buttonOffsetY
            let newX = box.maxX - newWidth
            if newX >= 0, newHeight + box.minY <= imageSize.height { 
                box.origin.x = newX
                box.size.width = newWidth
                box.size.height = newHeight
            }
        case 3: 
            let newWidth = max(10, adjustedX - box.minX) - buttonOffsetX
            let newHeight = max(10, adjustedY - box.minY)  - buttonOffsetY
            if newWidth + box.minX <= imageSize.width, newHeight + box.minY <= imageSize.height { 
                box.size.width = newWidth
                box.size.height = newHeight
            }
        default:
            break
        }
        labels[labelIndex].box = box
    }
    private func handleAnchorMovement(
        touch: CGPoint,
        for labelIndex: Int,
        imageWidth: CGFloat,
        imageHeight: CGFloat,
        imageOffsetX: CGFloat,
        imageOffsetY: CGFloat,
        buttonOffset: CGFloat,
        image: UIImage
    ) {
        guard labelIndex >= 0 && labelIndex < labels.count else { return }
        let imageSize = image.size
        let scaleX = imageWidth / imageSize.width
        let scaleY = imageHeight / imageSize.height
        let adjustedX = (touch.x - imageOffsetX) / scaleX
        let adjustedY = (touch.y - imageOffsetY) / scaleY
        let box = labels[labelIndex].box
        let anchorOffsetSize = buttonOffset + (box.height / 2)
        let anchorOffset: CGFloat = anchorOffsetSize
        let newBoxX = adjustedX - box.width / 2
        let newBoxY = adjustedY - box.height / 2 + anchorOffset
        if newBoxX >= 0, newBoxY >= 0, newBoxX + box.width <= imageSize.width, newBoxY + box.height <= imageSize.height {
            labels[labelIndex].box.origin.x = newBoxX
            labels[labelIndex].box.origin.y = newBoxY
        }
    }
    private func handlePencilDrawing(touch: UITouch, in view: UIView) {
        let location = touch.location(in: view)
        print("dr\(isDrawingEnabled)")
        switch touch.phase {
        case .began:
            print("drawing")
            startPoint = location
            isDrawingEnabled = true
        case .moved:
            isDrawingEnabled = true
            print("drawing moved")
            guard let start = startPoint else { startPoint = location; return }
            print("moved")
            let x = min(start.x, location.x)
            let y = min(start.y, location.y)
            let width = abs(location.x - start.x)
            let height = abs(location.y - start.y)
            currentDrawing = CGRect(x: x, y: y, width: width, height: height)
            isDrawingEnabled = true
        case .ended:
            guard let newBox = currentDrawing, let className = projectSettings.selectedClass?.name else { return }
            guard let image = image else {
                print("❌ No image loaded for dimension calculations.")
                return
            }
            let viewSize = view.frame.size
            let imageSize = image.size
            let scaleX = viewSize.width / imageSize.width
            let scaleY = viewSize.height / imageSize.height
            let aspectScale = min(scaleX, scaleY) 
            let offsetX = (viewSize.width - (imageSize.width * aspectScale)) / 2
            let offsetY = (viewSize.height - (imageSize.height * aspectScale)) / 2
            let adjustedBox = CGRect(
                x: (newBox.origin.x - offsetX) / aspectScale,
                y: (newBox.origin.y - offsetY) / aspectScale,
                width: newBox.width / aspectScale,
                height: newBox.height / aspectScale
            )
            guard adjustedBox.origin.x >= 0, adjustedBox.origin.y >= 0,
                  adjustedBox.maxX <= imageSize.width, adjustedBox.maxY <= imageSize.height else {
                print("❌ Invalid box coordinates: \(adjustedBox)")
                return
            }
            let newLabel = ClassLabel(
                imageName: currentImage, 
                className: className,
                box: adjustedBox,
                color: Color(platformColor: projectSettings.selectedClass?.color ?? .blue)
            )
            labels.append(newLabel)
            saveLabels()
            currentDrawing = nil
            isDrawingEnabled = false
        default:
            break
        }
    }
    private func saveLabels() {
        let labelStorageFormat = projectSettings.labelStorage
        saveLabelsInFormat(
            labelStorage: labelStorageFormat,
            filePath: folderURL, labelFileName: labelFileName,
            imageName: currentImage,
            labels: labels, classes: &projectSettings.classes
        )
    }
    private func loadLabels() {
        let labelsFileURL = folderURL.appendingPathComponent("labels.json")
        if let data = try? Data(contentsOf: labelsFileURL),
           let decodedAnnotations = try? JSONDecoder().decode([String: [ClassLabel]].self, from: data) {
            labels = decodedAnnotations[currentImage] ?? []
        } else {
            labels = [] 
        }
    }
}
extension CGRect {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = max(self.minX - point.x, 0, point.x - self.maxX)
        let dy = max(self.minY - point.y, 0, point.y - self.maxY)
        return sqrt(dx * dx + dy * dy)
    }
}

import SwiftUI

struct BoxLabelingView: View {
    let folderURL: URL
    let currentImage: String
    @Binding var selectedClass: YOLOClass?
    @Binding var image: UIImage?
    @Binding var labels: [ClassLabel]

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero
    @State private var currentDrawing: CGRect? = nil // Temporary box for drawing
    @State private var startPoint: CGPoint? = nil
    @State private var activeGesture: ActiveGesture = .none // Track active gestures
    

    enum ActiveGesture {
        case zoom, pan, draw, none
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Image
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(gestureCombo(in: geometry)) // Integrate zoom, pan, and draw
                }

                // Existing Bounding Boxes
                ForEach(labels) { label in
                    Rectangle()
                        .stroke(label.color, lineWidth: 2)
                        .frame(
                            width: label.box.width * scale,
                            height: label.box.height * scale
                        )
                        .position(
                            x: (label.box.origin.x + label.box.width / 2) * scale + offset.width,
                            y: (label.box.origin.y + label.box.height / 2) * scale + offset.height
                        )
                }

                // Current Drawing Overlay
                if let currentDrawing = currentDrawing {
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(
                            width: currentDrawing.width * scale,
                            height: currentDrawing.height * scale
                        )
                        .position(
                            x: (currentDrawing.origin.x + currentDrawing.width / 2) * scale + offset.width,
                            y: (currentDrawing.origin.y + currentDrawing.height / 2) * scale + offset.height
                        )
                }

                // Pencil Input
                PencilDrawingView { touch, view in
                    handlePencilDrawing(touch: touch, in: view)
                }
                .allowsHitTesting(true)
            }
        }
    }
    private func gestureCombo(in geometry: GeometryProxy) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                activeGesture = .zoom
                scale = value
            }
            .onEnded { _ in
                activeGesture = .none
            }
            .simultaneously(
                with: DragGesture()
                    .onChanged { value in
                        if activeGesture == .none || activeGesture == .pan {
                            activeGesture = .pan
                            offset = CGSize(
                                width: dragStartOffset.width + value.translation.width,
                                height: dragStartOffset.height + value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        if activeGesture == .pan {
                            dragStartOffset = offset
                            activeGesture = .none
                        }
                    }
            )
    }

    private func handlePencilDrawing(touch: UITouch, in view: UIView) {
        let location = touch.location(in: view)
        switch touch.phase {
        case .began:
            // Start a new box at the touch location
            print("starting")
            startPoint = location
//            currentDrawing = CGRect(origin: location, size: .zero)
        case .moved:
            guard let start = startPoint else { return }
            // Adjust for all directions
            let x = min(start.x, location.x)
            let y = min(start.y, location.y)
            let width = abs(location.x - start.x)
            let height = abs(location.y - start.y)
            print("\(start.x) x \(start.y) -> \(location.x) x \(location.y)")
            currentDrawing = CGRect(x: x, y: y, width: width, height: height)
        case .ended:
            print("ended")
            guard let newBox = currentDrawing, let className = selectedClass?.name else { return }
            // Add the new label to the list
            let newLabel = ClassLabel(
                imageName: currentImage, // Get the current image name
                className: className,
                box: newBox,
                color: selectedClass?.color ?? .blue
            )
            print("\(className) saving box \(newBox)")
            labels.append(newLabel)
            saveLabels()
            currentDrawing = nil
        default:
            break
        }
    }
    private func saveLabels() {
        let labelsFileURL = folderURL.appendingPathComponent("labels.json")
        var allAnnotations: [String: [ClassLabel]] = [:] // Dictionary to store annotations for all images
        print("saving...")

        // Load existing annotations
        if let data = try? Data(contentsOf: labelsFileURL),
           let decodedAnnotations = try? JSONDecoder().decode([String: [ClassLabel]].self, from: data) {
            allAnnotations = decodedAnnotations
        }

        allAnnotations[currentImage] = labels

        // Save updated annotations back to file
        do {
            let data = try JSONEncoder().encode(allAnnotations)
            try data.write(to: labelsFileURL, options: .atomic)
            print("✅ Labels saved successfully.")
        } catch {
            print("❌ Failed to save labels: \(error)")
        }
        print("saved")
    }
    private func loadLabels() {
        let labelsFileURL = folderURL.appendingPathComponent("labels.json")

        if let data = try? Data(contentsOf: labelsFileURL),
           let decodedAnnotations = try? JSONDecoder().decode([String: [ClassLabel]].self, from: data) {
            labels = decodedAnnotations[currentImage] ?? []
        } else {
            labels = [] // No annotations for the current image
        }
    }

}

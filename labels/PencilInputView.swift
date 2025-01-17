
import SwiftUI
struct PencilDrawingView: View {
    @Binding var useMouseAsPencil: Bool
    var onPencilEvent: (UITouch, UIView) -> Void
    var body: some View {
        #if os(iOS)
        PencilDrawingUIViewRepresentable(useMouseAsPencil: $useMouseAsPencil, onPencilEvent: onPencilEvent)
        #else
        Text("macOS support not implemented yet.") 
        #endif
    }
}
#if os(iOS)
struct PencilDrawingUIViewRepresentable: UIViewRepresentable {
    @Binding var useMouseAsPencil: Bool
    var onPencilEvent: (UITouch, UIView) -> Void
    func makeUIView(context: Context) -> PencilDrawingUIView {
        let view = PencilDrawingUIView()
        view.onPencilEvent = { touch, uiView in
            if useMouseAsPencil || touch.type == .pencil {
                onPencilEvent(touch, uiView)
            }
        }
        return view
    }
    func updateUIView(_ uiView: PencilDrawingUIView, context: Context) {}
}
class PencilDrawingUIView: UIView {
    var onPencilEvent: ((UITouch, UIView) -> Void)?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
    private func handleTouches(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        onPencilEvent?(touch, self) 
    }
}
#endif
#if os(macOS)
struct PencilDrawingNSViewRepresentable: NSViewRepresentable {
    @Binding var useMouseAsPencil: Bool
    var onMouseEvent: (UITouch, NSView) -> Void
    func makeNSView(context: Context) -> PencilDrawingNSView {
        let view = PencilDrawingNSView()
        view.onMouseEvent = { touch, nsView in
            if useMouseAsPencil || touch.phase == .moved || touch.phase == .began || touch.phase == .ended {
                onMouseEvent(touch, nsView)
            }
        }
        return view
    }
    func updateNSView(_ nsView: PencilDrawingNSView, context: Context) {}
}
class PencilDrawingNSView: NSView {
    var onMouseEvent: ((UITouch, NSView) -> Void)?
    override func mouseDown(with event: NSEvent) {
        handleMouse(event, phase: .began)
    }
    override func mouseDragged(with event: NSEvent) {
        handleMouse(event, phase: .moved)
    }
    override func mouseUp(with event: NSEvent) {
        handleMouse(event, phase: .ended)
    }
    private func handleMouse(_ event: NSEvent, phase: UITouch.Phase) {
        let location = event.locationInWindow
        let touch = UITouch(location: location, phase: phase)
        onMouseEvent?(touch, self) 
    }
}
#endif

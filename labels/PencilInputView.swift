import SwiftUI

struct PencilInputView: UIViewRepresentable {
    var onPencilEvent: (Set<UITouch>) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let pencilGestureRecognizer = PencilGestureRecognizer { touches in
            onPencilEvent(touches)
        }
        view.addGestureRecognizer(pencilGestureRecognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// Custom Gesture Recognizer
class PencilGestureRecognizer: UIGestureRecognizer {
    private let onTouches: (Set<UITouch>) -> Void

    init(onTouches: @escaping (Set<UITouch>) -> Void) {
        self.onTouches = onTouches
        super.init(target: nil, action: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        onTouches(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        onTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        onTouches(touches)
    }
}

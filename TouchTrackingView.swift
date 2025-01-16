import UIKit
import SwiftUI

struct TouchTrackingView: UIViewRepresentable {
    var onTouchBegan: ((CGPoint) -> Void)?
    var onTouchMoved: ((CGPoint) -> Void)?
    var onTouchEnded: ((CGPoint) -> Void)?

    func makeUIView(context: Context) -> TouchTrackingUIView {
        let view = TouchTrackingUIView()
        view.onTouchBegan = onTouchBegan
        view.onTouchMoved = onTouchMoved
        view.onTouchEnded = onTouchEnded
        return view
    }

    func updateUIView(_ uiView: TouchTrackingUIView, context: Context) {}

    class TouchTrackingUIView: UIView {
        var onTouchBegan: ((CGPoint) -> Void)?
        var onTouchMoved: ((CGPoint) -> Void)?
        var onTouchEnded: ((CGPoint) -> Void)?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let touch = touches.first {
                let location = touch.location(in: self)
                onTouchBegan?(location)
            }
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let touch = touches.first {
                let location = touch.location(in: self)
                onTouchMoved?(location)
            }
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let touch = touches.first {
                let location = touch.location(in: self)
                onTouchEnded?(location)
            }
        }
    }
}

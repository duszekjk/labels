
import SwiftUI
import Foundation
#if os(macOS)
import AppKit
typealias UIImage = NSImage
import AppKit
class UITouch {
    enum Phase {
        case began, moved, ended, cancelled
    }
    private let windowLocation: CGPoint
    let phase: Phase
    init(location: CGPoint, phase: Phase) {
        self.windowLocation = location
        self.phase = phase
    }
    func location(in view: NSView) -> CGPoint {
        guard let window = view.window else { return .zero }
        let screenRect = CGRect(origin: windowLocation, size: .zero)
        let windowPoint = window.convertFromScreen(screenRect).origin
        return view.convert(windowPoint, from: nil)
    }
}
typealias UIView = NSView
extension Image {
    init(uiImage: NSImage) {
        self.init(nsImage:uiImage)
    }
}
import Foundation
struct UIDevice {
    enum UserInterfaceIdiom {
        case mac
        case phone
        case pad
    }
    enum Orientation {
        case landscape
        case portrait
    }
    static var current: UIDevice {
        UIDevice()
    }
    var userInterfaceIdiom: UserInterfaceIdiom {
        return .mac
    }
    var orientation: Orientation {
        return .landscape
    }
}
extension UIDevice.Orientation {
    var isLandscape: Bool {
        self == .landscape
    }
    var isPortrait: Bool {
        self == .portrait
    }
}
#endif

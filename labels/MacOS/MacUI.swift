
import SwiftUI
import Foundation

#if os(macOS)
import Combine
import AppKit
import Cocoa

typealias UIImage = NSImage
extension NSImage {
    /// Mimics `UIImage.pngData()` from iOS
    func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    /// Mimics `UIImage.jpegData(compressionQuality:)` from iOS
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
extension Image {
    init(uiImage: NSImage) {
        self.init(nsImage:uiImage)
    }
}

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
struct UIDevice {
    enum UserInterfaceIdiom {
        case mac
        case phone
        case pad
    }
    enum Orientation {
        case landscapeLeft
        case landscapeRight
        case portrait
    }
    static var current: UIDevice {
        UIDevice()
    }
    var userInterfaceIdiom: UserInterfaceIdiom {
        return .mac
    }
    var orientation: UIDevice.Orientation {
        return .landscapeLeft
    }
    static let orientationDidChangeNotification = Notification.Name("UIDevice.orientationDidChangeNotification")
}
extension UIDevice.Orientation {
    var isLandscape: Bool {
        self == .landscapeLeft || self == .landscapeRight
    }
    var isPortrait: Bool {
        self == .portrait
    }
}
extension Notification.Name {
    static let orientationDidChangeNotification = Notification.Name("UIDevice.orientationDidChangeNotification")
}

class DeviceOrientationManager {
    static let shared = DeviceOrientationManager()
    private var screenChangeObserver: Any?

    private init() {
        // Observe screen parameter changes
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .orientationDidChangeNotification, object: nil)
        }
    }

    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// Mimic UIApplication
class UIApplication {
    static let shared = UIApplication()
    var connectedScenes: Set<UIWindowScene> = [UIWindowScene()]
}

// Mimic UIWindowScene
class UIWindowScene: Hashable {
    var interfaceOrientation: UIInterfaceOrientation {
        guard let mainScreen = NSScreen.main else { return .unknown }
        return mainScreen.frame.width > mainScreen.frame.height ? .landscapeRight : .portrait
    }
    
    // Conformance to Hashable
    static func == (lhs: UIWindowScene, rhs: UIWindowScene) -> Bool {
        // Assuming a single instance of UIWindowScene for simplicity
        return lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        // Hashing the memory address (identity) of the instance
        hasher.combine(ObjectIdentifier(self))
    }
}

// Mimic UIInterfaceOrientation
enum UIInterfaceOrientation {
    case unknown
    case portrait
    case landscapeLeft
    case landscapeRight
}






#endif
#if os(iOS)
typealias PlatformColor = UIColor
#elseif os(macOS)
typealias PlatformColor = NSColor
#endif
extension PlatformColor {
    func toHex() -> String {
        #if os(iOS)
        guard let components = cgColor.components else { return "#000000" }
        #elseif os(macOS)
        guard let components = usingColorSpace(.deviceRGB)?.cgColor.components else { return "#000000" }
        #endif
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        guard let hexNumber = UInt32(hexSanitized, radix: 16) else { return nil }
        let r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
        let g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
        let b = CGFloat(hexNumber & 0x0000FF) / 255
        #if os(iOS)
        self.init(red: r, green: g, blue: b, alpha: 1.0)
        #elseif os(macOS)
        self.init(red: r, green: g, blue: b, alpha: 1.0)
        #endif
    }
}
#if os(macOS)
extension PlatformColor {
    static var secondarySystemGroupedBackground: PlatformColor {
        return PlatformColor.windowBackgroundColor // Replace with a close alternative
    }

    static var systemGroupedBackground: PlatformColor {
        return PlatformColor.controlBackgroundColor // Replace with a close alternative
    }

    // Add more semantic color mappings if needed
}
#endif
extension Color {
    init(platformColor: PlatformColor) {
        #if os(iOS)
        self.init(uiColor:platformColor)
        #elseif os(macOS)
        self.init(nsColor:platformColor)
        #endif
    }
}
#if os(macOS)
import AppKit

class UIScreen {
    /// Singleton instance for `UIScreen.main`
    static let main = UIScreen()

    /// The screen bounds, mimicking iOS behavior
    var bounds: CGRect {
        return NSApplication.shared.keyWindow?.frame ?? NSScreen.main?.frame ?? .zero
    }

    /// The screen scale (e.g., Retina vs. standard display)
    var scale: CGFloat {
        return NSScreen.main?.backingScaleFactor ?? 1.0
    }

    /// The screen brightness (defaulted, as macOS doesn't have a direct API)
    var brightness: CGFloat {
        // Placeholder for brightness. Can be extended with external APIs.
        return 1.0
    }

    /// The screen size (derived from bounds)
    var size: CGSize {
        return bounds.size
    }

    /// The screen width (derived from bounds)
    var width: CGFloat {
        return bounds.width
    }

    /// The screen height (derived from bounds)
    var height: CGFloat {
        return bounds.height
    }

    // Add other properties or methods as needed to mimic `UIScreen`
}

#endif

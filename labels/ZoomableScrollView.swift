
#if os(iOS)
import SwiftUI
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    func updateUIView(_ uiView: PencilDetectingScrollView, context: Context) {
        uiView.zoomScale = zoomScale
        uiView.isScrollEnabled = !isDrawingEnabled && !isScrollDisabled
        if let hostedView = uiView.subviews.first {
            hostedView.frame = CGRect(origin: .zero, size: uiView.contentSize)
        }
    }
    typealias UIViewType = PencilDetectingScrollView
    var content: Content
    @Binding var zoomScale: CGFloat
    @Binding var isDrawingEnabled: Bool
    @Binding var isScrollDisabled: Bool
    var onSwitchView: ((Direction) -> Void)?
    var defaultZoomScale: CGFloat
    init(
        zoomScale: Binding<CGFloat>,
        isDrawingEnabled: Binding<Bool>,
        isScrollDisabled: Binding<Bool>,
        onSwitchView: ((Direction) -> Void)? = nil,
        defaultZoomScale:CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self._zoomScale = zoomScale
        self._isDrawingEnabled = isDrawingEnabled
        self._isScrollDisabled = isScrollDisabled
        self.content = content()
        self.onSwitchView = onSwitchView
        self.defaultZoomScale = defaultZoomScale
    }
    func makeUIView(context: Context) -> PencilDetectingScrollView {
        let scrollView = PencilDetectingScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = defaultZoomScale
        scrollView.maximumZoomScale = 3.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.zoomScale = zoomScale
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        hostingController.view.frame = CGRect(origin: .zero, size: hostingController.view.intrinsicContentSize)
        hostingController.view.backgroundColor = .clear
        scrollView.addSubview(hostingController.view)
        scrollView.contentSize = hostingController.view.intrinsicContentSize
        scrollView.onDrawingEnabledChange = { isEnabled in
            scrollView.isScrollEnabled = !isDrawingEnabled && !isScrollDisabled
            if(isEnabled)
            {
                scrollView.isScrollEnabled = false
            }
        }
        DispatchQueue.main.async {
            let centerOffsetX = max(0, (scrollView.contentSize.width - scrollView.bounds.width) / 2)
            let centerOffsetY = max(0, (scrollView.contentSize.height - scrollView.bounds.height) / 2)
            scrollView.contentOffset = CGPoint(x: centerOffsetX, y: centerOffsetY)
        }
        return scrollView
    }
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        uiView.zoomScale = zoomScale
        uiView.isScrollEnabled = !isDrawingEnabled && !isScrollDisabled
        if let hostedView = uiView.subviews.first {
            hostedView.frame = CGRect(origin: .zero, size: uiView.contentSize)
        }
    }
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(zoomScale: $zoomScale, isDrawingEnabled: $isDrawingEnabled, isScrollDisabled: $isScrollDisabled, defaultZoomScale: defaultZoomScale)
        coordinator.onScrollBeyondBounds = onSwitchView
        return coordinator
    }
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        @Binding var zoomScale: CGFloat
        @Binding var isDrawingEnabled: Bool
        @Binding var isScrollDisabled: Bool
        var defaultZoomScale: CGFloat
        var onScrollBeyondBounds: ((Direction) -> Void)?
        init(zoomScale: Binding<CGFloat>, isDrawingEnabled: Binding<Bool>, isScrollDisabled: Binding<Bool>, defaultZoomScale: CGFloat) {
            self._zoomScale = zoomScale
            self._isDrawingEnabled = isDrawingEnabled
            self._isScrollDisabled = isScrollDisabled
            self.defaultZoomScale = defaultZoomScale
        }
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.subviews.first
        }
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            zoomScale = scrollView.zoomScale
        }
        private var isAdjustingContentOffset = false
        private var lastSwitchTime: Date = .distantPast
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isAdjustingContentOffset else { return }
            let offsetX = scrollView.contentOffset.x
            let contentWidth = scrollView.contentSize.width
            let boundsWidth = scrollView.bounds.width
            let zoomScale = scrollView.zoomScale
            let minZoom: CGFloat = defaultZoomScale - 0.01
            let maxZoom: CGFloat = defaultZoomScale + 0.1
            guard zoomScale >= minZoom && zoomScale <= maxZoom else {
                return
            }
            let effectiveContentWidth = max(contentWidth, boundsWidth / zoomScale)
            if offsetX < -0.02 * effectiveContentWidth {
                guard Date().timeIntervalSince(lastSwitchTime) > 0.5 else { return }
                lastSwitchTime = Date()
                isAdjustingContentOffset = true
                scrollView.contentOffset.x = effectiveContentWidth - boundsWidth + 0.015 * effectiveContentWidth
                onScrollBeyondBounds?(.left)
                isAdjustingContentOffset = false
            } else if offsetX > (contentWidth - boundsWidth) + 0.02 * effectiveContentWidth {
                guard Date().timeIntervalSince(lastSwitchTime) > 0.5 else { return }
                lastSwitchTime = Date()
                isAdjustingContentOffset = true
                scrollView.contentOffset.x = -0.15 * effectiveContentWidth
                onScrollBeyondBounds?(.right)
                isAdjustingContentOffset = false
            }
        }
    }
}
import UIKit
class PencilTouchGestureRecognizer: UIGestureRecognizer {
    var onPencilTouch: ((Bool) -> Void)?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, touch.type == .pencil {
            onPencilTouch?(true) 
            state = .failed
        } else {
            onPencilTouch?(false) 
            state = .failed
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, touch.type == .pencil {
            state = .failed
        }
        state = .failed
        onPencilTouch?(false) 
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
    override func reset() {
        state = .possible
    }
}
class PencilDetectingScrollView: UIScrollView {
    var onDrawingEnabledChange: ((Bool) -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestureRecognizer()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestureRecognizer()
    }
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.isScrollEnabled
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            print("touchesBegan \(touch.type)")
            if touch.type == .pencil {
                onDrawingEnabledChange?(true)
                self.isScrollEnabled = false
            }
        }
        super.touchesBegan(touches, with: event)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, touch.type == .pencil {
            return
        }
        super.touchesMoved(touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, touch.type == .pencil {
            onDrawingEnabledChange?(false)
        }
        super.touchesEnded(touches, with: event)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        onDrawingEnabledChange?(false)
        super.touchesCancelled(touches, with: event)
    }
    private func setupGestureRecognizer() {
        let pencilRecognizer = PencilTouchGestureRecognizer()
        pencilRecognizer.onPencilTouch = { [weak self] isDrawing in
            guard let self = self else { return }
            self.onDrawingEnabledChange?(isDrawing)
        }
        addGestureRecognizer(pencilRecognizer)
    }
}
#elseif os(macOS)
#if os(macOS)
import SwiftUI
import AppKit
struct ZoomableScrollView<Content: View>: NSViewRepresentable {
    func updateNSView(_ nsView: PencilDetectingScrollView, context: Context) {
        nsView.magnification = zoomScale
        nsView.allowsMagnification = !isDrawingEnabled && !isScrollDisabled
        if let hostedView = nsView.documentView?.subviews.first {
            hostedView.frame = CGRect(origin: .zero, size: nsView.documentView?.frame.size ?? .zero)
        }
    }
    typealias NSViewType = PencilDetectingScrollView
    var content: Content
    @Binding var zoomScale: CGFloat
    @Binding var isDrawingEnabled: Bool
    @Binding var isScrollDisabled: Bool
    var onSwitchView: ((Direction) -> Void)?
    var defaultZoomScale: CGFloat
    init(
        zoomScale: Binding<CGFloat>,
        isDrawingEnabled: Binding<Bool>,
        isScrollDisabled: Binding<Bool>,
        onSwitchView: ((Direction) -> Void)? = nil,
        defaultZoomScale:CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self._zoomScale = zoomScale
        self._isDrawingEnabled = isDrawingEnabled
        self._isScrollDisabled = isScrollDisabled
        self.content = content()
        self.onSwitchView = onSwitchView
        self.defaultZoomScale = defaultZoomScale
    }
    func makeNSView(context: Context) -> PencilDetectingScrollView {
        let scrollView = PencilDetectingScrollView()
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.125
        scrollView.maxMagnification = 2.0
        scrollView.magnification = zoomScale
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        let hostingController = NSHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        hostingController.view.frame = CGRect(origin: .zero, size: hostingController.view.fittingSize)
        scrollView.documentView = hostingController.view
        DispatchQueue.main.async {
            let centerOffsetX = max(0, (scrollView.contentSize.width - scrollView.bounds.width) / 2)
            let centerOffsetY = max(0, (scrollView.contentSize.height - scrollView.bounds.height) / 2)
            scrollView.contentView.scroll(to: CGPoint(x: centerOffsetX, y: centerOffsetY))
        }
        return scrollView
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale, isDrawingEnabled: $isDrawingEnabled, isScrollDisabled: $isScrollDisabled, defaultZoomScale: defaultZoomScale)
    }
    class Coordinator: NSObject, NSGestureRecognizerDelegate {
        @Binding var zoomScale: CGFloat
        @Binding var isDrawingEnabled: Bool
        @Binding var isScrollDisabled: Bool
        var defaultZoomScale: CGFloat
        var onScrollBeyondBounds: ((Direction) -> Void)?
        init(zoomScale: Binding<CGFloat>, isDrawingEnabled: Binding<Bool>, isScrollDisabled: Binding<Bool>, defaultZoomScale: CGFloat) {
            self._zoomScale = zoomScale
            self._isDrawingEnabled = isDrawingEnabled
            self._isScrollDisabled = isScrollDisabled
            self.defaultZoomScale = defaultZoomScale
        }
    }
}
class PencilDetectingScrollView: NSScrollView {
    var onDrawingEnabledChange: ((Bool) -> Void)?
    override func magnify(with event: NSEvent) {
        super.magnify(with: event)
        onDrawingEnabledChange?(false) 
    }
    override func mouseDown(with event: NSEvent) {
        if event.type == .leftMouseDown {
            onDrawingEnabledChange?(true) 
        }
        super.mouseDown(with: event)
    }
    override func mouseUp(with event: NSEvent) {
        if event.type == .leftMouseUp {
            onDrawingEnabledChange?(false) 
        }
        super.mouseUp(with: event)
    }
}
#endif
#endif
enum Direction {
    case left
    case right
}

struct ZoomableScrollView<Content: View>: View {
    let content: Content

    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                content
                    .scaleEffect(zoomScale)
                    .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                    .frame(
                        width: geometry.size.width * zoomScale,
                        height: geometry.size.height * zoomScale
                    )
                    .gesture(
                        MagnificationGesture()
                            .updating($gestureScale) { value, state, _ in
                                state = value
                            }
                            .onEnded { value in
                                zoomScale *= value
                            }
                    )
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                offset.width += value.translation.width
                                offset.height += value.translation.height
                            }
                    )
            }
        }
    }
}

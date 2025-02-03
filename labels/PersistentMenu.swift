import SwiftUI

struct PersistentMenu<Content: View, Label: View>: View {
    @State private var isMenuOpen = false
    @State private var buttonFrame: CGRect = .zero // Track the button's position
    @State private var buttonPosition: CGPoint = .zero

    let label: Label
    let content: Content

    init(@ViewBuilder _ content: () -> Content, @ViewBuilder label: () -> Label) {
        self.label = label()
        self.content = content()
    }

    var body: some View {
        HStack {
                label
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                // Open menu at touch location on start
                                GlobalMenuManager.shared.showMenu(
                                    content: { content },
                                    at: gesture.location
                                )
                                print("in button \(gesture.location.x) x \(gesture.location.y)")
                            }
                    )

        }
        .padding(0)
    }

}



struct  menuDividerPadding: View {
    var body: some View {
        Divider().padding(.vertical, 2).padding(.horizontal, 0)
    }
}

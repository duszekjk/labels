//
//  GlobalMenuManager.swift
//  labels
//
//  Created by Jacek Kałużny on 17/01/2025.
//


import SwiftUI

class GlobalMenuManager: ObservableObject {
    static let shared = GlobalMenuManager() // Singleton instance
    
    @Published var isMenuOpen = false
    @Published var menuContent: AnyView = AnyView(EmptyView()) // Menu content
    @Published var menuPosition: CGPoint = .zero // Position of the menu
}
struct GlobalMenuOverlay: View {
    @ObservedObject var manager = GlobalMenuManager.shared
    @State private var contentHeight: CGFloat = 0 // Track the height of the menu content


    var body: some View {
        ZStack {
            if manager.isMenuOpen {
                // Background overlay for dismissing the menu
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                print("in overlay \(gesture.location.x) x \(gesture.location.y)")
                            }
                    )
                    .onTapGesture {
                        manager.isMenuOpen = false // Close the menu
                    }

                // Menu content positioned dynamically
                VStack(spacing: 0) {
                    manager.menuContent
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear {
                                        contentHeight = proxy.size.height // Capture the height of the menu content
                                    }
                            }
                        )
                        .padding(8)
                        .background(
                            VisualEffectBlur() // Add blur effect
                                .cornerRadius(10)
                        )
                        .foregroundColor(Color(UIColor.label))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .frame(width: 280)
                        .position(CGPoint(x: min(max(20, manager.menuPosition.x + 200), UIScreen.main.bounds.size.width - 150), y:  contentHeight / 2 + 50))
                }
            }
        }
        .animation(.easeInOut, value: manager.isMenuOpen) // Smooth open/close
    }
}
extension GlobalMenuManager {
    func showMenu<Content: View>(@ViewBuilder content: () -> Content, at position: CGPoint) {
        let menuItems = VStack(spacing: 0) {
            content()
                .environment(\.menuButtonStyle, AnyViewModifier { view in
                    AnyView(view.modifier(MenuButtonStyle())) // Wrap modified view in AnyView
                })
        }
        self.menuContent = AnyView(menuItems)
        self.menuPosition = position
        self.isMenuOpen = true
    }
}


struct MenuButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .overlay(
                Divider().padding(.leading), alignment: .bottom
            )
            .buttonStyle(PlainButtonStyle()) // Disable default animations
    }
}

struct MenuButtonStyleKey: EnvironmentKey {
    static let defaultValue: AnyViewModifier = AnyViewModifier { $0 }
}

extension EnvironmentValues {
    var menuButtonStyle: AnyViewModifier {
        get { self[MenuButtonStyleKey.self] }
        set { self[MenuButtonStyleKey.self] = newValue }
    }
}
struct AnyViewModifier: ViewModifier {
    let transform: (AnyView) -> AnyView

    init(transform: @escaping (AnyView) -> AnyView) {
        self.transform = transform
    }

    func body(content: Content) -> some View {
        transform(AnyView(content))
    }
}

extension View {
    func menuButtonStyle() -> some View {
        self.modifier(MenuButtonStyle())
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

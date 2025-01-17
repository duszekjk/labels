import SwiftUI
    #if os(macOS)
func isApplePencilEvent(touches: Any) -> Bool {
    return false
}
    #else
func isApplePencilEvent(touches: Set<UITouch>) -> Bool {
    for touch in touches {
        if touch.type == .pencil {
            return true
        }
    }
    return false
}
    #endif

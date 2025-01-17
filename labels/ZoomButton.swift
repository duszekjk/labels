
import SwiftUI
struct ZoomButton: View {
    let zoomLevel: CGFloat
    @Binding var currentZoom: CGFloat
    let label: String
    var body: some View {
        Button(action: {
            currentZoom = zoomLevel
        }) {
            ZStack {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .offset(x: -3, y: -3) 
            }
        }
    }
}
struct ZoomButtons: View {
    @Binding var zoomScale: CGFloat
    var defaultZoomScale: CGFloat
    var body: some View {
        Spacer()
        HStack(spacing: 1)
        {
            ZoomButton(zoomLevel: defaultZoomScale, currentZoom: $zoomScale, label: "1")
            ZoomButton(zoomLevel: defaultZoomScale*2, currentZoom: $zoomScale, label: "2")
            ZoomButton(zoomLevel: defaultZoomScale*3, currentZoom: $zoomScale, label: "3")
            ZoomButton(zoomLevel: defaultZoomScale*4, currentZoom: $zoomScale, label: "4")
        }
        Text("\(zoomScale*500.0, specifier: "%.2f") %")
        Spacer()
    }
}

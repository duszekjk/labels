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
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
                    .offset(x: -5, y: -5) // Position the number inside the glass
            }
        }
    }
}
import SwiftUI

struct ImageGalleryView: View {
    @Binding var images: [URL]
    @Binding var currentIndex: Int
    @Binding var image: UIImage?
    @Binding var imageName: String
    
    var loadImage: (Int) -> Void
    var onCancel: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 10)
    ]

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(images.indices, id: \.self) { index in
                            VStack {
                                Image(uiImage: loadImageFromURL(images[index]))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(currentIndex == index ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        currentIndex = index
                                        loadImage(index)
                                    }

                                Text(images[index].lastPathComponent)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select an Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onCancel()
                    }
                }
            }
        }
    }

    private func loadImageFromURL(_ url: URL) -> UIImage {
        if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
            return uiImage
        }
        return UIImage(systemName: "photo") ?? UIImage()
    }
}

struct ImageGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ImageGalleryView(
            images: .constant([]),
            currentIndex: .constant(0),
            image: .constant(nil),
            imageName: .constant("None"),
            loadImage: { _ in },
            onCancel: {}
        )
    }
}

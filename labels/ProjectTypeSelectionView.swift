
import SwiftUI
struct ProjectTypeSelectionView: View {
    var onTypeSelected: (DatasetType) -> Void
    var onLoadSelected: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text("Load Project")
                .font(.title)
            Button("Select Directory") {
                onLoadSelected()
            }
            .buttonStyle(.borderedProminent)
            Divider()
                .padding(.vertical)
            Text("Create New Project")
                .font(.title)
            Text("Choose Project Type")
            Button("Classification") {
                onTypeSelected(.classification)
            }
            Button("Bounding Box Annotation") {
                onTypeSelected(.boundingBox)
            }
            Button("Instance Segmentation") {
                onTypeSelected(.instanceSegmentation)
            }
            Button("Semantic Segmentation") {
                onTypeSelected(.semanticSegmentation)
            }
        }
        .padding()
    }
}

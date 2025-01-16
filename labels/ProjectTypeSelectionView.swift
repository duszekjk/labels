import SwiftUI

struct ProjectTypeSelectionView: View {
    @State private var selectedProjectType: DatasetType?
    @State private var navigateToDirectorySelection = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Project Type")
                .font(.title)
            
            Button("Classification") {
                selectedProjectType = .classification
                navigateToDirectorySelection = true
            }
            
            Button("Bounding Box Annotation") {
                selectedProjectType = .boundingBox
                navigateToDirectorySelection = true
            }
            
            Button("Instance Segmentation") {
                selectedProjectType = .instanceSegmentation
                navigateToDirectorySelection = true
            }
            
            Button("Semantic Segmentation") {
                selectedProjectType = .semanticSegmentation
                navigateToDirectorySelection = true
            }
        }
        .navigationDestination(isPresented: $navigateToDirectorySelection) {
            DirectorySelectionView(projectType: selectedProjectType!)
        }
    }
}

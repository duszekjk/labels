
import SwiftUI
extension MainView{
    var menuView: some View {
        HStack() {
            if selectedLabel == nil {
                Button(action: { showDatasetLevel = true }) {
                    Text("Dataset Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .sheet(isPresented: $showDatasetLevel) {
                    DatasetCorrectionView(folderURL: folderURL, projectSettings: $projectSettings)
                }
            } else {
                labelAdjustmentMenu
            }
        }
        .font(.headline)
    }
    var labelAdjustmentMenu: some View {
        HStack() {
            movementButtons
            resizeButtons
            classPickerButton
        }
    }
    var movementButtons: some View {
        HStack {
            
            if(UIDevice.current.userInterfaceIdiom == .phone)
            {
                PersistentMenu
                {
                    arrowButton(icon: "arrow.down", action: { moveLabel(dx: 0, dy: speedMove) }, name: "Move label down")
                    menuDividerPadding()
                    arrowButton(icon: "arrow.up", action: { moveLabel(dx: 0, dy: -1.0*speedMove) }, name: "Move label up")
                    menuDividerPadding()
                    arrowButton(icon: "arrow.left", action: { moveLabel(dx: -1.0*speedMove, dy: 0) }, name: "Move label left")
                    menuDividerPadding()
                    arrowButton(icon: "arrow.right", action: { moveLabel(dx: speedMove, dy: 0) }, name: "Move label right")
                }
                label: {
                   Label("", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.purple)
                        .cornerRadius(10)
               }
            }
            else
            {
                arrowButton(icon: "arrow.down", action: { moveLabel(dx: 0, dy: speedMove) })
                arrowButton(icon: "arrow.up", action: { moveLabel(dx: 0, dy: -1.0*speedMove) })
                arrowButton(icon: "arrow.left", action: { moveLabel(dx: -1.0*speedMove, dy: 0) })
                arrowButton(icon: "arrow.right", action: { moveLabel(dx: speedMove, dy: 0) })
            }
        }
    }
    var resizeButtons: some View {
        HStack {
            if(UIDevice.current.userInterfaceIdiom == .phone)
            {
                Menu
                {
                    actionButton(icon: "minus", color: .red, action: { resizeLabel(scaleFactor: 1.0 - speedMove*2.0) }, name: "Label size")
                    actionButton(icon: "plus", color: .green, action: { resizeLabel(scaleFactor: 1.0 + speedMove*2.0) }, name: "Label size")
                }
                label: {
                    Label("", systemImage: "square.resize")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            else
            {
                actionButton(icon: "minus", color: .red, action: { resizeLabel(scaleFactor: 1.0 - speedMove*2.0) })
                actionButton(icon: "plus", color: .green, action: { resizeLabel(scaleFactor: 1.0 + speedMove*2.0) })
            }
            actionButton(icon: "trash", color: .red, action: {
                if let selectedLabelBox = labels.first(where: { $0.id == selectedLabel })
                {
                    removeLabel(selectedLabelBox)
                    selectedLabel = nil
                }
            })
            .padding(.trailing, -20.0)
        }
    }
    var classPickerButton: some View {
        Menu {
            ForEach(projectSettings.classes, id: \.id) { yoloClass in
                Button(action: { changeClass(to: yoloClass) }) {
                    Text(yoloClass.name)
                }
            }
        } label: {
            Image(systemName: "tag")
                .font(.headline)
                .frame(width: 40, height: 40)
                .background(Color.yellow)
                .cornerRadius(10)
        }
    }
    func arrowButton(icon: String, action: @escaping () -> Void, name:String? = nil) -> some View {
        Button(action: action) {
            if(name != nil)
            {
                Text(name!)
                Spacer()
            }
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
    }
    func actionButton(icon: String, color: Color, action: @escaping () -> Void, name:String? = nil) -> some View {
        Button(action: action) {
            if(name != nil)
            {
                Text(name!)
                Spacer()
            }
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(10)
        }
    }
    func moveLabel(dx: CGFloat, dy: CGFloat) {
        guard let selected = selectedLabel,
              let index = labels.firstIndex(where: { $0.id == selected }) else { return }
        let imageWidth = image?.size.width ?? 1
        let imageHeight = image?.size.height ?? 1
        labels[index].box.origin.x += dx * imageWidth
        labels[index].box.origin.y += dy * imageHeight
        let labelStorageFormat = projectSettings.labelStorage
        saveLabelsInFormat(
            labelStorage: labelStorageFormat,
            filePath: folderURL, labelFileName: labelFileName,
            imageName: imageName,
            labels: labels,
            classes: &projectSettings.classes
        )
    }
}

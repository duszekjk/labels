
import SwiftUI
struct SideBar: View {
    let folderURL: URL
    @Binding var projectSettings: ProjectSettings
    @Binding var projectSettingsManager: ProjectSettingsManager?
    @Binding var labels: [ClassLabel]
    @Binding var selectedLabel: UUID?
    let saveSettings: () -> Void
    let removeLabel: (ClassLabel) -> Void
    let deleteLabel: (IndexSet) -> Void
    @State private var newClassName: String = ""
    @State private var newClassColor: Color = .blue
    @State private var newClassCount: Int = 0
    var body: some View {
        List(selection: $projectSettings.selectedClass) {
            Section(header: Text("Add Classes"), content:
                        {
                VStack
                {
                    TextField("Class Name", text: $newClassName)
                        .textFieldStyle(.roundedBorder)
                    HStack
                    {
                        ColorPicker("Class Color", selection: $newClassColor)
                        Spacer()
                        Button(action: {
                            addNewClass()
                        }) {
                            Label("Add label", systemImage: "plus")
                        }
                    }
                }
            }
            )
            Section(header: Text("Classes")) {
                ForEach(projectSettings.classes) { yoloClass in
                    HStack {
                        Circle()
                            .fill(Color(platformColor: yoloClass.color))
                            .frame(width: 20, height: 20)
                        Text(yoloClass.name)
                        Text(" (\(yoloClass.occurrenceCount))")
                    }
                    .tag(yoloClass)
                }
            }
            Section(header: Text("Labels")) {
                ForEach(labels) { label in
                    HStack {
                        Circle()
                            .fill(label.color)
                            .frame(width: 20, height: 20)
                        VStack(alignment: .leading) {
                            Text(label.className)
                                .font(.headline)
                                .foregroundColor(label.selected ? .blue : .primary)
                            Text("\(label.box.origin.x, specifier: "%.1f") x \(label.box.origin.y, specifier: "%.1f")")
                                .font(.caption)
                            Text("\(label.box.width, specifier: "%.1f") x \(label.box.height, specifier: "%.1f")")
                                .font(.caption)
                        }
                        Spacer()
                        Button(action: {
                            removeLabel(label)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle()) 
                    }
                    .padding(.init(top: 1.0, leading: 5.0, bottom: 1.0, trailing: 5.0))
                    .contentShape(Rectangle()) 
                    .onTapGesture {
                        selectLabel(label)
                    }
                    .background((selectedLabel == label.id) ? Color.blue.opacity(0.1) : Color.clear) 
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .onDelete(perform: deleteLabel) 
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Classes")
    }
    func addNewClass() {
        let newClass = YOLOClass(name: newClassName, color: PlatformColor(newClassColor), occurrenceCount: newClassCount)
        projectSettings.classes.append(newClass)
        newClassName = ""
        newClassColor = .blue
        newClassCount = 0
        projectSettings.selectedClass = projectSettings.classes.last
        saveSettings()
    }
    private func selectLabel(_ label: ClassLabel) {
        if(selectedLabel == label.id)
        {
            selectedLabel = nil
            for index in labels.indices {
                labels[index].selected = (labels[index].id == selectedLabel)
            }
        }
        else
        {
            selectedLabel = label.id
            for index in labels.indices {
                labels[index].selected = (labels[index].id == selectedLabel)
            }
        }
    }
}

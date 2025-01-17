            List(selection: $projectSettings.selectedClass) {
                Section(header: Text("Classes")) {
                    ForEach(projectSettings.classes) { yoloClass in
                        HStack {
                            Circle()
                                .fill(Color(uiColor: yoloClass.color))
                                .frame(width: 20, height: 20)
                            Text(yoloClass.name)
                            Text(" (\(yoloClass.occurrenceCount))")
                        }
                        .tag(yoloClass)
                    }
                }
                Section(header: Text("Add Classes"), content:
                            
                            {
                                VStack
                                {
                                    TextField("Class Name", text: $newClassName)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    ColorPicker("Class Color", selection: $newClassColor)
                                    
                                    Stepper("Occurrence Count: \(newClassCount)", value: $newClassCount, in: 0...100)
                                    
                                    Button(action: {
                                        addNewClass()
                                    }) {
                                        Label("Add", systemImage: "plus")
                                    }
                                }
                            }
                        )
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
                                        .buttonStyle(BorderlessButtonStyle()) // Prevent row selection on tap
                                    }
                                    .padding(.init(top: 1.0, leading: 5.0, bottom: 1.0, trailing: 5.0))
                                    .contentShape(Rectangle()) // Makes the entire row tappable
                                    .onTapGesture {
                                        selectLabel(label)
                                    }
                                    .background((selectedLabel == label.id) ? Color.blue.opacity(0.1) : Color.clear) // Visual feedback
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                }
                                .onDelete(perform: deleteLabel) // Swipe-to-delete support
                            }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Classes")
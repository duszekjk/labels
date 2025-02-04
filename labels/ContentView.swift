import SwiftUI
struct ContentView: View {
    @StateObject private var folderAccessManager = FolderAccessManager()
    @State private var selectedProjectType: DatasetType?
    @State private var projectSettings: ProjectSettings = ProjectSettings(name: "", description: "", hashtags: [], datasetType: .none, labelStorage: "", creationDate: Date.now, lastModifiedDate: Date.now, directoryPath: "", imageSubdirectory: "", labelSubdirectory: "", classes: [])
    @State private var showSavePicker = false
    @State private var showLoadPicker = false
    @State private var showGetData = false
    @State private var navigateToMainView = false
    @State private var workflowStep: WorkflowStep = .none
    @State private var folderUrl: URL? = nil
    var body: some View {
        VStack {
            if selectedProjectType == nil {
                ProjectTypeSelectionView(
                    onTypeSelected: { type in
                        selectedProjectType = type
                        workflowStep = .saving
                        showSavePicker = true
                    },
                    onLoadSelected: {
                        workflowStep = .loading
                        showSavePicker = true
                    }
                )
            }
            else
            {
                if workflowStep == .ready
                {
                    if let folderURL = folderUrl {
                        MainView(folderURL: folderURL, selectedProjectType: $selectedProjectType, projectSettings: $projectSettings, projectIsOpenned: $navigateToMainView)
                            .onAppear()
                            {
                                print("main is visible")
                                folderAccessManager.folderURL = folderURL
                            }
                    }
                }
                else
                {
                    ProgressView(value: 0.25)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showSavePicker, onDismiss: {
            if workflowStep == .saving {
                workflowStep = .gettingData
                showGetData = true
            }
            if workflowStep == .loading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { 
                    if folderUrl != nil {
                        print("workflowStep .loading")
                        let projectSettingsMenager = ProjectSettingsManager(settings: nil, directoryURL: folderUrl)
                        projectSettings = projectSettingsMenager.settings
                        selectedProjectType = projectSettings.datasetType
                        navigateToMainView = true
                        workflowStep = .ready
                    } else {
                        print("folderUrl = nil in workflowStep .loading")
                    }
                }
            }
        }) {
            FolderPicker(folderURL: $folderUrl, workflowStep: $workflowStep, showSavePicker: $showSavePicker)
        }
        .sheet(isPresented: $showGetData, onDismiss: {
            if workflowStep == .gettingData {
                workflowStep = .ready
                navigateToMainView = true
            }
        }) {
            if let selectedProjectType = selectedProjectType
            {
                CreateProjectSettingsView(datasetType: selectedProjectType, folderUrl: folderUrl, projectSettings: $projectSettings, showGetData: $showGetData)
            }
        }
    }
}
enum WorkflowStep {
    case none
    case saving
    case gettingData
    case loading
    case loadingB
    case ready
}

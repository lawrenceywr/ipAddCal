import SwiftUI
import IPCalculatorFeatures

struct ContentView: View {
    @State private var workbench = CalculatorWorkbenchViewModel()

    var body: some View {
        @Bindable var workbench = workbench

        NavigationSplitView {
            SidebarNavigationView(selection: $workbench.navigation.selectedWorkspace)
        } detail: {
            Group {
                switch workbench.navigation.selectedWorkspace {
                case .ipCalculation:
                    IPWorkspaceView(workbench: workbench)
                case .baseConversion:
                    BaseConversionView(viewModel: workbench.baseConversionWorkspace)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(workbench.windowTitle)
                        .font(.headline)
                }

                ToolbarItem {
                    Button("历史") {
                        workbench.navigation.isHistoryPresented.toggle()
                    }
                    .popover(isPresented: $workbench.navigation.isHistoryPresented) {
                        HistoryPopoverView(
                            entries: workbench.history.entries,
                            onCopy: { _ in },
                            onRestore: { entry in
                                workbench.restore(entry)
                            }
                        )
                    }
                }
            }
        }
    }
}

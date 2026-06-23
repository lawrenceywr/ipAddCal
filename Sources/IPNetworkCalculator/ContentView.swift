import SwiftUI
import IPCalculatorFeatures

struct ContentView: View {
    @State private var workbench = CalculatorWorkbenchViewModel()
    private let theme = CalculatorTheme.defaultDark

    var body: some View {
        @Bindable var workbench = workbench

        NavigationSplitView {
            SidebarNavigationView(selection: $workbench.navigation.selectedWorkspace)
                .calculatorChromeBackground()
        } detail: {
            Group {
                switch workbench.navigation.selectedWorkspace {
                case .ipCalculation:
                    IPWorkspaceView(workbench: workbench)
                case .baseConversion:
                    BaseConversionView(viewModel: workbench.baseConversionWorkspace)
                }
            }
            .padding(WorkspaceChrome.contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(theme.windowBase.gradient)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(workbench.windowTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.94))
                }

                ToolbarItem {
                    Button("历史") {
                        workbench.navigation.isHistoryPresented.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .popover(isPresented: $workbench.navigation.isHistoryPresented) {
                        HistoryPopoverView(
                            entries: workbench.history.entries,
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

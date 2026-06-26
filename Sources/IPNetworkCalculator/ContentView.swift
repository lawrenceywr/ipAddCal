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
            .calculatorChromeBackground(fillOpacity: theme.chrome.detailFillOpacity)
            .navigationTitle(workbench.windowTitle)
            .toolbar {
                ToolbarItem {
                    Button {
                        workbench.navigation.isHistoryPresented.toggle()
                    } label: {
                        Text("历史")
                    }
                    .buttonStyle(.plain)
                    .calculatorHistoryButtonChrome()
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
        .toolbarBackground(theme.chromeBase.opacity(theme.chrome.detailFillOpacity), for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        .toolbarColorScheme(.dark, for: .windowToolbar)
    }
}

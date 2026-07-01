import SwiftUI
import IPCalculatorFeatures

struct ContentView: View {
    @State private var workbench = CalculatorWorkbenchViewModel()
    private let theme = CalculatorTheme.defaultDark

    var body: some View {
        @Bindable var workbench = workbench

        HStack(spacing: 0) {
            SidebarNavigationView(selection: $workbench.navigation.selectedWorkspace)
                .frame(width: theme.chrome.integratedSidebarWidth)
                .background(theme.chromeBase.opacity(theme.chrome.sidebarFillOpacity))

            Rectangle()
                .fill(.white.opacity(theme.chrome.integratedSidebarDividerOpacity))
                .frame(width: 1)

            VStack(spacing: 0) {
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
            }
            .background(theme.windowBase.gradient)
        }
        .background(theme.windowBase.gradient)
        .toolbar {
            ToolbarItem {
                Button {
                    workbench.navigation.isHistoryPresented.toggle()
                } label: {
                    Text("历史")
                        .calculatorHistoryButtonChrome()
                }
                .buttonStyle(.plain)
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
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(theme.chrome.toolbarLineOpacity))
                .frame(height: 1)
        }
        .toolbarBackground(theme.chromeBase.opacity(theme.chrome.detailFillOpacity), for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        .toolbarColorScheme(.dark, for: .windowToolbar)
    }
}

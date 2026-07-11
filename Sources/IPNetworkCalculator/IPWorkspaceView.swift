import SwiftUI
import IPCalculatorFeatures

struct IPWorkspaceView: View {
    @Bindable var workbench: CalculatorWorkbenchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CalculatorWorkspaceHeader(
                route: "WORKSPACE / IP_CALCULATOR",
                title: "NETWORK TERMINAL",
                subtitle: "解析 IPv4 / IPv6 地址、子网与映射关系"
            )

            IPWorkspacePickerView(selection: $workbench.navigation.selectedIPMode)

            switch workbench.navigation.selectedIPMode {
            case .network:
                NetworkWorkspaceView(
                    viewModel: workbench.networkWorkspace,
                    onCalculate: { workbench.calculateCurrentIPWorkspace() }
                )
            case .translation:
                TranslationWorkspaceView(
                    viewModel: workbench.translationWorkspace,
                    onCalculate: { workbench.calculateCurrentIPWorkspace() }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

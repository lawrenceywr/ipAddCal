import SwiftUI
import IPCalculatorFeatures

struct IPWorkspaceView: View {
    @Bindable var workbench: CalculatorWorkbenchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

import SwiftUI
import IPCalculatorFeatures

struct NetworkWorkspaceView: View {
    @Bindable var viewModel: NetworkWorkspaceViewModel
    let onCalculate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WorkspaceChrome.sectionSpacing) {
            VStack(alignment: .leading, spacing: 14) {
                field(
                    "地址/前缀或掩码",
                    example: "192.168.1.10/24、10.0.0.7/255.255.255.248 或 2001:db8::1/126",
                    text: Binding(
                        get: { viewModel.networkInput },
                        set: { newValue in viewModel.updateNetworkInput(newValue) }
                    )
                )

                HStack {
                    Spacer()
                    Button("计算") {
                        onCalculate()
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(WorkspaceChrome.surfacePadding)
            .calculatorFormSurface()

            ResultPanelView(
                statusText: viewModel.statusText,
                errorMessage: viewModel.errorMessage,
                sections: viewModel.resultSections,
                primaryCopyLabel: viewModel.primaryCopyLabel,
                primaryCopyText: viewModel.primaryCopyText,
                copyAllText: viewModel.copyAllText
            )

            Spacer(minLength: 0)
        }
    }

    private func field(_ title: String, example: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: WorkspaceChrome.fieldLabelSpacing) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(example)
                .font(.footnote)
                .foregroundStyle(CalculatorTheme.defaultDark.secondaryLabel)
            NormalizingTextField(title, text: text, onSubmit: onCalculate)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.plain)
                .calculatorFieldChrome()
        }
    }

}

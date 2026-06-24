import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct TranslationWorkspaceView: View {
    @Bindable var viewModel: TranslationWorkspaceViewModel
    let onCalculate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WorkspaceChrome.sectionSpacing) {
            VStack(alignment: .leading, spacing: 14) {
                TranslationDirectionPickerView(selection: $viewModel.direction)

                switch viewModel.direction {
                case .ipv4ToIPv6:
                    HStack(spacing: WorkspaceChrome.controlSpacing) {
                        field("IPv4 网段", example: "48.235.24.0/30", text: $viewModel.ipv4Input)
                        field("IPv6 前 96 位", example: "2001:db8::", text: $viewModel.ipv6PrefixInput)
                    }
                case .ipv6ToIPv4:
                    HStack(spacing: WorkspaceChrome.controlSpacing) {
                        field(
                            "IPv6 地址/网段",
                            example: "2001:db8::30eb:1800/126",
                            text: $viewModel.ipv6Input
                        )
                        field(
                            "IPv6 /96 前缀（可选）",
                            example: "2001:db8::",
                            text: $viewModel.ipv6ReversePrefixInput
                        )
                    }
                }

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
            TextField(title, text: normalizedBinding(text))
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.plain)
                .calculatorFieldChrome()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func normalizedBinding(_ text: Binding<String>) -> Binding<String> {
        Binding(
            get: { text.wrappedValue },
            set: { newValue in
                text.wrappedValue = InputNormalizer.normalizeFieldText(newValue)
            }
        )
    }
}

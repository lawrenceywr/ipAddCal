import SwiftUI
import IPCalculatorFeatures

struct TranslationWorkspaceView: View {
    @Bindable var viewModel: TranslationWorkspaceViewModel
    @Environment(\.calculatorTheme) private var theme
    @State private var focusedFieldTitle: String?
    let onCalculate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WorkspaceChrome.sectionSpacing) {
            VStack(alignment: .leading, spacing: 14) {
                TranslationDirectionPickerView(selection: $viewModel.direction)

                switch viewModel.direction {
                case .ipv4ToIPv6:
                    HStack(spacing: WorkspaceChrome.controlSpacing) {
                        field(
                            "IPv4 网段",
                            example: "48.235.24.0/30",
                            invalidField: .ipv4Input,
                            text: Binding(
                                get: { viewModel.ipv4Input },
                                set: { newValue in viewModel.updateIPv4Input(newValue) }
                            )
                        )
                        field(
                            "IPv6 前 96 位",
                            example: "2001:db8::",
                            invalidField: .ipv6PrefixInput,
                            text: Binding(
                                get: { viewModel.ipv6PrefixInput },
                                set: { newValue in viewModel.updateIPv6PrefixInput(newValue) }
                            )
                        )
                    }
                case .ipv6ToIPv4:
                    HStack(spacing: WorkspaceChrome.controlSpacing) {
                        field(
                            "IPv6 地址/网段",
                            example: "2001:db8::30eb:1800/126",
                            invalidField: .ipv6Input,
                            text: Binding(
                                get: { viewModel.ipv6Input },
                                set: { newValue in viewModel.updateIPv6Input(newValue) }
                            )
                        )
                        field(
                            "IPv6 /96 前缀（可选）",
                            example: "2001:db8::",
                            invalidField: .ipv6ReversePrefixInput,
                            text: Binding(
                                get: { viewModel.ipv6ReversePrefixInput },
                                set: { newValue in viewModel.updateIPv6ReversePrefixInput(newValue) }
                            )
                        )
                    }
                }

                HStack {
                    Spacer()
                    Button("计算") {
                        onCalculate()
                    }
                    .keyboardShortcut(.return)
                    .calculatorPrimaryActionChrome()
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

    private func field(
        _ title: String,
        example: String,
        invalidField: TranslationInputField,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: WorkspaceChrome.fieldLabelSpacing) {
            fieldLabel(title)
            Text(example)
                .font(.footnote)
                .foregroundStyle(theme.secondaryLabel)
            NormalizingTextField(
                title,
                text: text,
                isFocused: focusBinding(for: title),
                onSubmit: onCalculate
            )
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.plain)
                .calculatorFieldChrome(
                    invalid: viewModel.invalidField == invalidField,
                    focused: focusedFieldTitle == title
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func focusBinding(for title: String) -> Binding<Bool> {
        Binding(
            get: { focusedFieldTitle == title },
            set: { focused in
                if focused {
                    focusedFieldTitle = title
                } else if focusedFieldTitle == title {
                    focusedFieldTitle = nil
                }
            }
        )
    }

    @ViewBuilder
    private func fieldLabel(_ title: String) -> some View {
        if theme.visualStyle == .neonTactical {
            HStack(spacing: 7) {
                Text("01 //")
                    .foregroundStyle(theme.accentSecondary)
                    .accessibilityHidden(true)
                Text(title)
                    .foregroundStyle(theme.primaryLabel)
            }
            .font(.system(.subheadline, design: .monospaced).weight(.bold))
            .tracking(0.6)
        } else {
            Text(title).font(.subheadline.weight(.semibold))
        }
    }

}

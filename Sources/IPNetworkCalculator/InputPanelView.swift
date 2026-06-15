import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct InputPanelView: View {
    @Bindable var viewModel: CalculatorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch viewModel.mode {
            case .network:
                field(
                    "地址/前缀或掩码",
                    example: "192.168.1.10/24、10.0.0.7/255.255.255.248 或 2001:db8::1/126",
                    text: $viewModel.networkInput
                )
            case .ipv4ToIPv6:
                HStack(spacing: 12) {
                    field("IPv4 网段", example: "48.235.24.0/30", text: $viewModel.ipv4Input)
                    field("IPv6 前 96 位", example: "2001:db8::", text: $viewModel.ipv6PrefixInput)
                }
            case .ipv6ToIPv4:
                HStack(spacing: 12) {
                    field("IPv6 地址/网段", example: "2001:db8::30eb:1800/126", text: $viewModel.ipv6ReverseInput)
                    field("IPv6 /96 前缀（可选）", example: "2001:db8::", text: $viewModel.ipv6ReversePrefixInput)
                }
            case .baseConversion:
                EmptyView()
            }

            HStack {
                Spacer()
                Button("计算") {
                    viewModel.calculate()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .calculatorGlassPanel()
    }

    private func field(_ title: String, example: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(example)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let normalized = InputNormalizer.normalizeFieldText(newValue)
                    if normalized != newValue {
                        text.wrappedValue = normalized
                    }
                }
        }
    }
}

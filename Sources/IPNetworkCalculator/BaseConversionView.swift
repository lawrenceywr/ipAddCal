import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct BaseConversionView: View {
    @Bindable var viewModel: BaseConversionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                baseField("二进制", text: viewModel.binaryText, base: .binary)
                baseField("十进制", text: viewModel.decimalText, base: .decimal)
                baseField("十六进制", text: viewModel.hexadecimalText, base: .hexadecimal)
            }
            BinaryBitGridView(binary32: viewModel.binary32) { bitIndex in
                viewModel.toggle(bitIndex: bitIndex)
            }
            if let message = viewModel.errorMessage {
                Text(message).foregroundStyle(.red)
            }
        }
        .padding()
        .calculatorWorkspaceSurface()
    }

    private func baseField(_ title: String, text: String, base: NumberBase) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            TextField(title, text: Binding(
                get: { text },
                set: { newValue in viewModel.update(text: newValue, base: base) }
            ))
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(viewModel.invalidBase == base ? Color.red : Color.clear, lineWidth: 1)
                }
        }
    }
}

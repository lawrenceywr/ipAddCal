import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct BaseConversionView: View {
    @Binding var state: BaseConversionState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                baseField("二进制", text: $state.binaryText, base: .binary)
                baseField("十进制", text: $state.decimalText, base: .decimal)
                baseField("十六进制", text: $state.hexadecimalText, base: .hexadecimal)
            }
            BinaryBitGridView(binary32: state.binary32) { bitIndex in
                state.toggle(bitIndex: bitIndex)
            }
            if let message = state.errorMessage {
                Text(message).foregroundStyle(.red)
            }
        }
        .padding()
        .calculatorGlassPanel()
    }

    private func baseField(_ title: String, text: Binding<String>, base: NumberBase) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            TextField(title, text: text)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .onChange(of: text.wrappedValue) { _, newValue in
                    state.update(text: newValue, base: base)
                }
        }
    }
}

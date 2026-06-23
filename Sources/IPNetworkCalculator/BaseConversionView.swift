import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct BaseConversionLayout {
    let binarySurfacePadding = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
    let binarySectionSpacing: CGFloat = 8
}

struct BaseConversionView: View {
    @Bindable var viewModel: BaseConversionViewModel
    private let layout = BaseConversionLayout()

    var body: some View {
        VStack(alignment: .leading, spacing: WorkspaceChrome.sectionSpacing) {
            HStack(alignment: .top, spacing: WorkspaceChrome.controlSpacing) {
                baseField("二进制", text: viewModel.binaryText, base: .binary)
                baseField("十进制", text: viewModel.decimalText, base: .decimal)
                baseField("十六进制", text: viewModel.hexadecimalText, base: .hexadecimal)
            }
            .padding(WorkspaceChrome.surfacePadding)
            .calculatorWorkspaceSurface()

            VStack(alignment: .leading, spacing: layout.binarySectionSpacing) {
                BinaryBitGridView(binary32: viewModel.binary32) { bitIndex in
                    viewModel.toggle(bitIndex: bitIndex)
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(layout.binarySurfacePadding)
            .calculatorWorkspaceSurface()

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func baseField(_ title: String, text: String, base: NumberBase) -> some View {
        VStack(alignment: .leading, spacing: WorkspaceChrome.fieldLabelSpacing) {
            Text(title).font(.subheadline.weight(.semibold))
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

import SwiftUI
import IPCalculatorFeatures

struct ResultPanelView: View {
    @Bindable var viewModel: CalculatorViewModel
    @State private var feedback = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(feedback.isEmpty ? viewModel.statusText : feedback)
                    .font(.headline)
                    .foregroundStyle(viewModel.errorMessage == nil ? Color.primary : Color.red)
                Spacer()
                if !viewModel.copyNetworkText.isEmpty {
                    Button("复制 \(viewModel.copyNetworkLabel)") {
                        ClipboardService.copy(viewModel.copyNetworkText)
                        flash("已复制：\(viewModel.copyNetworkLabel)")
                    }
                }
                if !viewModel.copyAllText.isEmpty {
                    Button("复制全部") {
                        ClipboardService.copy(viewModel.copyAllText)
                        flash("已复制：全部结果")
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red)
            } else if viewModel.resultRows.isEmpty {
                Text("暂无结果").foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    ForEach(viewModel.resultRows) { row in
                        GridRow {
                            Text(row.label).foregroundStyle(.secondary)
                            Text(row.value)
                                .font(.system(.body, design: .monospaced).bold())
                                .textSelection(.enabled)
                                .onTapGesture {
                                    ClipboardService.copy(row.value)
                                    flash("已复制：\(row.label)")
                                }
                        }
                    }
                }
            }
        }
        .padding()
        .glassEffect()
    }

    private func flash(_ text: String) {
        feedback = text
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            feedback = ""
        }
    }
}

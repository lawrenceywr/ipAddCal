import SwiftUI
import IPCalculatorFeatures

struct ResultPanelView: View {
    let statusText: String
    let errorMessage: String?
    let sections: [ResultSection]
    let primaryCopyLabel: String
    let primaryCopyText: String
    let copyAllText: String

    @State private var feedback = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(feedback.isEmpty ? statusText : feedback)
                    .font(.headline)
                    .foregroundStyle(errorMessage == nil ? Color.primary : Color.red)
                Spacer()
                if !primaryCopyText.isEmpty {
                    Button("复制 \(primaryCopyLabel)") {
                        ClipboardService.copy(primaryCopyText)
                        flash("已复制：\(primaryCopyLabel)")
                    }
                    .controlSize(.small)
                }
                if !copyAllText.isEmpty {
                    Button("复制全部") {
                        ClipboardService.copy(copyAllText)
                        flash("已复制：全部结果")
                    }
                    .controlSize(.small)
                }
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else if sections.isEmpty {
                Text("暂无结果").foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sections) { section in
                        GroupBox {
                            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                                ForEach(section.rows) { row in
                                    GridRow {
                                        Text(row.label).foregroundStyle(.secondary)
                                        Button {
                                            ClipboardService.copy(row.value)
                                            flash("已复制：\(row.label)")
                                        } label: {
                                            Text(row.value)
                                                .font(.system(.body, design: .monospaced).bold())
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)
                                        .help("复制\(row.label)")
                                        .contextMenu {
                                            Button("复制") {
                                                ClipboardService.copy(row.value)
                                                flash("已复制：\(row.label)")
                                            }
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text(section.title)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
        }
        .padding(WorkspaceChrome.surfacePadding)
        .calculatorWorkspaceSurface()
    }

    private func flash(_ text: String) {
        feedback = text
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            feedback = ""
        }
    }
}

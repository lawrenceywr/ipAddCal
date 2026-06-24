import SwiftUI
import IPCalculatorFeatures

struct ResultPanelView: View {
    private let theme = CalculatorTheme.defaultDark

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
                    .foregroundStyle(errorMessage == nil ? .white : theme.error)
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
                Text(errorMessage).foregroundStyle(theme.error)
            } else if sections.isEmpty {
                Text("暂无结果").foregroundStyle(theme.secondaryLabel)
            } else {
                VStack(alignment: .leading, spacing: theme.resultSection.rowSpacing) {
                    ForEach(sections) { section in
                        ResultSectionContainer(title: section.title, theme: theme) {
                            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                                ForEach(section.rows) { row in
                                    GridRow {
                                        Text(row.label)
                                            .foregroundStyle(theme.secondaryLabel)
                                        Button {
                                            ClipboardService.copy(row.value)
                                            flash("已复制：\(row.label)")
                                        } label: {
                                            Text(row.value)
                                                .font(.system(.body, design: .monospaced).bold())
                                                .foregroundStyle(.white)
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

private struct ResultSectionContainer<Content: View>: View {
    let title: String
    let theme: CalculatorTheme
    @ViewBuilder let content: Content

    var body: some View {
        let chrome = theme.resultSection

        VStack(alignment: .leading, spacing: chrome.headerSpacing) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            content
        }
        .padding(.horizontal, chrome.horizontalPadding)
        .padding(.vertical, chrome.verticalPadding)
        .background(
            theme.chromeElevated.opacity(chrome.fillOpacity),
            in: RoundedRectangle(cornerRadius: chrome.cornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: chrome.cornerRadius, style: .continuous)
                .stroke(.white.opacity(chrome.strokeOpacity), lineWidth: 1)
        }
    }
}

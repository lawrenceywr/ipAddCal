import SwiftUI
import IPCalculatorFeatures

struct HistorySidebarView: View {
    var history: HistoryStore

    var body: some View {
        List(history.entries) { entry in
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(.body, design: .monospaced).bold())
                    .textSelection(.enabled)
                Text(entry.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contextMenu {
                Button("复制") {
                    ClipboardService.copy(entry.copyText)
                }
            }
        }
        .overlay {
            if history.entries.isEmpty {
                Text("暂无历史记录").foregroundStyle(.secondary)
            }
        }
    }
}

import SwiftUI
import IPCalculatorFeatures

struct HistorySidebarView: View {
    var history: HistoryStore
    @State private var copiedEntryID: HistoryEntry.ID?

    var body: some View {
        List(history.entries) { entry in
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(.body, design: .monospaced).bold())
                        .textSelection(.enabled)
                    Text(entry.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(copiedEntryID == entry.id ? "已复制" : "复制") {
                    copy(entry)
                }
                .controlSize(.small)
            }
            .contextMenu {
                Button("复制") {
                    copy(entry)
                }
            }
        }
        .overlay {
            if history.entries.isEmpty {
                Text("暂无历史记录").foregroundStyle(.secondary)
            }
        }
    }

    private func copy(_ entry: HistoryEntry) {
        ClipboardService.copy(entry.copyText)
        copiedEntryID = entry.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            if copiedEntryID == entry.id {
                copiedEntryID = nil
            }
        }
    }
}

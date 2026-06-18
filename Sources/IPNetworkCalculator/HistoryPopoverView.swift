import SwiftUI
import IPCalculatorFeatures

struct HistoryPopoverView: View {
    let entries: [HistoryEntry]
    let onRestore: (HistoryEntry) -> Void

    @State private var copiedEntryID: HistoryEntry.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史记录")
                .font(.headline)

            if entries.isEmpty {
                Text("暂无历史记录")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(entry.title)
                                    .font(.system(.body, design: .monospaced).bold())
                                    .textSelection(.enabled)

                                Text(entry.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 8) {
                                    Button(copiedEntryID == entry.id ? "已复制" : "复制") {
                                        copy(entry)
                                    }

                                    Button("恢复") {
                                        onRestore(entry)
                                    }
                                    .disabled(entry.restoreTarget == nil)
                                }
                                .controlSize(.small)
                            }

                            if entry.id != entries.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .padding(16)
        .frame(width: 360, alignment: .leading)
        .calculatorPopoverSurface()
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

import Foundation

public struct HistoryStore: Equatable, Sendable {
    public private(set) var entries: [HistoryEntry] = []
    public var maxEntries = 8

    public init() {}

    public mutating func add(entry: HistoryEntry) {
        guard !entry.copyText.isEmpty else { return }

        entries.removeAll { $0.copyText == entry.copyText }
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeSubrange(maxEntries..<entries.count)
        }
    }

    public mutating func add(title: String, subtitle: String, copyText: String) {
        add(entry: HistoryEntry(title: title, subtitle: subtitle, copyText: copyText))
    }
}

import Foundation

public struct HistoryStore: Equatable, Sendable {
    public private(set) var entries: [HistoryEntry] = []
    public var maxEntries = 8

    public init() {}

    public mutating func add(title: String, subtitle: String, copyText: String) {
        guard !copyText.isEmpty else { return }

        entries.removeAll { $0.copyText == copyText }
        entries.insert(HistoryEntry(title: title, subtitle: subtitle, copyText: copyText), at: 0)
        if entries.count > maxEntries {
            entries.removeSubrange(maxEntries..<entries.count)
        }
    }
}

import Testing
@testable import IPCalculatorFeatures

@Test
func dedupesAndCapsHistoryAtEight() {
    var store = HistoryStore()
    for index in 1...10 {
        store.add(
            title: "10.0.\(index).0/24",
            subtitle: "网段计算 · 10.0.\(index).1/24",
            copyText: "10.0.\(index).0/24"
        )
    }
    store.add(
        title: "10.0.10.0/24",
        subtitle: "网段计算 · 10.0.10.1/24",
        copyText: "10.0.10.0/24"
    )

    #expect(store.entries.count == 8)
    #expect(store.entries.first?.title == "10.0.10.0/24")
}

@Test
func dedupesTypedHistoryEntriesAndKeepsRestoreTarget() {
    var store = HistoryStore()
    store.add(
        entry: HistoryEntry(
            title: "192.168.1.0/24",
            subtitle: "网段计算 · 192.168.1.10/24",
            copyText: "192.168.1.0/24",
            restoreTarget: .network(input: "192.168.1.10/24")
        )
    )
    store.add(
        entry: HistoryEntry(
            title: "192.168.1.0/24",
            subtitle: "网段计算 · 192.168.1.10/24",
            copyText: "192.168.1.0/24",
            restoreTarget: .network(input: "192.168.1.10/24")
        )
    )

    #expect(store.entries.count == 1)
    #expect(store.entries.first?.restoreTarget == .network(input: "192.168.1.10/24"))
}

@Test
func preservesDistinctRestoreTargetsWhenCopyTextMatches() {
    var store = HistoryStore()
    let sharedCopyText = "2001:db8::30eb:1800/126"

    store.add(
        entry: HistoryEntry(
            title: sharedCopyText,
            subtitle: "V4 -> V6 · 48.235.24.0/30",
            copyText: sharedCopyText,
            restoreTarget: .ipv4ToIPv6(
                ipv4Input: "48.235.24.0/30",
                ipv6PrefixInput: "2001:db8::"
            )
        )
    )
    store.add(
        entry: HistoryEntry(
            title: sharedCopyText,
            subtitle: "网段计算 · \(sharedCopyText)",
            copyText: sharedCopyText,
            restoreTarget: .network(input: sharedCopyText)
        )
    )

    #expect(store.entries.count == 2)
    #expect(store.entries.map(\.restoreTarget) == [
        .network(input: sharedCopyText),
        .ipv4ToIPv6(ipv4Input: "48.235.24.0/30", ipv6PrefixInput: "2001:db8::")
    ])
}

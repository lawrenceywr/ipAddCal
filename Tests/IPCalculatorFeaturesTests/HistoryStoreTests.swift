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

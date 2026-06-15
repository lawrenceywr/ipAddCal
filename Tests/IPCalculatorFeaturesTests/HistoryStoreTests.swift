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

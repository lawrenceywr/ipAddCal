import Testing
@testable import IPCalculatorFeatures

@Test
func resultSectionEqualityIncludesExplicitIdentity() {
    let rows = [ResultRow(label: "网段", value: "192.168.1.0/24")]

    #expect(
        ResultSection(id: "network.core", title: "核心结果", rows: rows)
            != ResultSection(id: "network.extended", title: "核心结果", rows: rows)
    )
}

@MainActor
@Test
func networkWorkspaceBuildsGroupedRowsAndHistoryEntry() {
    let viewModel = NetworkWorkspaceViewModel()
    viewModel.networkInput = "192.168.1.10/24"

    let entry = viewModel.calculate()

    #expect(viewModel.statusText == "192.168.1.0/24")
    #expect(viewModel.resultSections.map(\.title) == ["核心结果", "扩展结果"])
    #expect(viewModel.resultSections.first?.rows.map(\.label) == ["网段", "地址数量", "首个地址", "最后地址"])
    #expect(viewModel.resultSections.first?.rows.map(\.value) == ["192.168.1.0/24", "256", "192.168.1.0", "192.168.1.255"])
    #expect(viewModel.resultSections.dropFirst().first?.rows.map(\.label) == ["C段数量"])
    #expect(viewModel.resultSections.dropFirst().first?.rows.map(\.value) == ["1"])
    #expect(viewModel.copyAllText == """
    网段: 192.168.1.0/24
    地址数量: 256
    首个地址: 192.168.1.0
    最后地址: 192.168.1.255
    C段数量: 1
    """)
    #expect(viewModel.primaryCopyLabel == "网段")
    #expect(viewModel.primaryCopyText == "192.168.1.0/24")
    #expect(entry?.subtitle == "网段计算 · 192.168.1.0/24")
    #expect(entry?.copyText == "192.168.1.0/24")
    #expect(entry?.restoreTarget == .network(input: "192.168.1.10/24"))
}

@MainActor
@Test
func networkWorkspaceNormalizesChinesePunctuationAsTextChanges() {
    let viewModel = NetworkWorkspaceViewModel()

    viewModel.updateNetworkInput("１９２。１６８。１。１０、２４")

    #expect(viewModel.networkInput == "192.168.1.10/24")
}

@MainActor
@Test
func networkWorkspaceRestoreResetsStaleState() {
    let viewModel = NetworkWorkspaceViewModel()
    viewModel.resultSections = [
        ResultSection(
            id: "network.core",
            title: "核心结果",
            rows: [ResultRow(label: "网段", value: "stale")]
        )
    ]
    viewModel.statusText = "错误"
    viewModel.errorMessage = "stale"
    viewModel.copyAllText = "stale"
    viewModel.primaryCopyText = "stale"
    viewModel.primaryCopyLabel = "stale"

    viewModel.restore(input: " １９２．１６８．１．１０／２４ ")

    #expect(viewModel.networkInput == "192.168.1.10/24")
    #expect(viewModel.resultSections.isEmpty)
    #expect(viewModel.statusText == "等待输入...")
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.copyAllText == "")
    #expect(viewModel.primaryCopyText == "")
    #expect(viewModel.primaryCopyLabel == "网段")
}

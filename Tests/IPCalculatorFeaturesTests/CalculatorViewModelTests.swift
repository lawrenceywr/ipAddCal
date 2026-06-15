import IPCalculatorCore
import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func calculatesStandardNetworkRowsAndCopyText() {
    let viewModel = CalculatorViewModel()
    viewModel.networkInput = "192.168.1.10/24"
    viewModel.calculate()

    #expect(viewModel.statusText == "192.168.1.0/24")
    #expect(viewModel.resultRows.map(\.label) == ["网段", "地址数量", "首个地址", "最后地址", "C段数量"])
    #expect(viewModel.resultRows.first?.value == "192.168.1.0/24")
    #expect(viewModel.copyAllText.contains("网段: 192.168.1.0/24"))
    #expect(viewModel.copyNetworkText == "192.168.1.0/24")
    #expect(viewModel.copyNetworkLabel == "网段")
    #expect(viewModel.history.entries.first?.title == "192.168.1.0/24")
}

@MainActor
@Test
func calculatesIPv4ToIPv6RowsAndPrimaryCopyText() {
    let viewModel = CalculatorViewModel()
    viewModel.mode = .ipv4ToIPv6
    viewModel.ipv4Input = "48.235.24.0/30"
    viewModel.ipv6PrefixInput = "2001:db8::"
    viewModel.calculate()

    #expect(viewModel.statusText == "IPv6 网段已生成")
    #expect(viewModel.resultRows.map(\.label) == ["IPv4 网段", "IPv6 前缀", "IPv6 网段", "地址数量", "首个地址", "最后地址"])
    #expect(viewModel.copyNetworkText == "2001:db8::30eb:1800/126")
    #expect(viewModel.copyNetworkLabel == "IPv6 网段")
    #expect(viewModel.history.entries.first?.subtitle == "V4 -> V6 · 48.235.24.0/30")
}

@MainActor
@Test
func calculatesIPv6ToIPv4RowsAndPrimaryCopyText() {
    let viewModel = CalculatorViewModel()
    viewModel.mode = .ipv6ToIPv4
    viewModel.ipv6ReverseInput = "2001:db8::30eb:1800/126"
    viewModel.ipv6ReversePrefixInput = "2001:db8::"
    viewModel.calculate()

    #expect(viewModel.statusText == "IPv4 网段已反算")
    #expect(viewModel.resultRows.map(\.label) == ["IPv6 前缀", "IPv6 网段", "IPv4 网段", "地址数量", "首个 IPv4", "最后 IPv4"])
    #expect(viewModel.copyNetworkText == "48.235.24.0/30")
    #expect(viewModel.copyNetworkLabel == "IPv4 网段")
    #expect(viewModel.history.entries.first?.subtitle == "V6 -> V4 · 2001:db8::30eb:1800/126")
}

@MainActor
@Test
func synchronizesBaseConversionState() {
    var state = BaseConversionState()
    state.update(text: "255", base: .decimal)

    #expect(state.binaryText == "11111111")
    #expect(state.decimalText == "255")
    #expect(state.hexadecimalText == "FF")
    #expect(state.binary32.filter { $0 == "1" }.count == 8)

    state.toggle(bitIndex: 31)
    #expect(state.decimalText == "2147483903")
}

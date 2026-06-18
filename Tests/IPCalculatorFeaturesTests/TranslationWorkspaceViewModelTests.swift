import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func translationWorkspaceBuildsIpv4ToIpv6ResultAndHistoryEntry() {
    let viewModel = TranslationWorkspaceViewModel()
    viewModel.direction = .ipv4ToIPv6
    viewModel.ipv4Input = "48.235.24.0/30"
    viewModel.ipv6PrefixInput = "2001:db8::"

    let entry = viewModel.calculate()

    #expect(viewModel.resultSections.map(\.title) == ["生成结果", "地址范围"])
    #expect(viewModel.primaryCopyLabel == "IPv6 网段")
    #expect(viewModel.primaryCopyText == "2001:db8::30eb:1800/126")
    #expect(entry?.subtitle == "V4 -> V6 · 48.235.24.0/30")
    #expect(entry?.restoreTarget == .ipv4ToIPv6(ipv4Input: "48.235.24.0/30", ipv6PrefixInput: "2001:db8::"))
}

@MainActor
@Test
func translationWorkspaceBuildsIpv6ToIpv4ResultAndHistoryEntry() {
    let viewModel = TranslationWorkspaceViewModel()
    viewModel.direction = .ipv6ToIPv4
    viewModel.ipv6Input = "2001:db8::30eb:1800/126"
    viewModel.ipv6ReversePrefixInput = "2001:db8::"

    let entry = viewModel.calculate()

    #expect(viewModel.statusText == "IPv4 网段已反算")
    #expect(viewModel.primaryCopyLabel == "IPv4 网段")
    #expect(viewModel.primaryCopyText == "48.235.24.0/30")
    #expect(entry?.subtitle == "V6 -> V4 · 2001:db8::30eb:1800/126")
    #expect(entry?.restoreTarget == .ipv6ToIPv4(ipv6Input: "2001:db8::30eb:1800/126", ipv6PrefixInput: "2001:db8::"))
}

@MainActor
@Test
func translationWorkspaceRestoreSupportsIpv4ToIpv6Direction() {
    let viewModel = TranslationWorkspaceViewModel()
    viewModel.resultSections = [
        ResultSection(
            id: "translation.generated",
            title: "生成结果",
            rows: [ResultRow(label: "IPv6 网段", value: "x")]
        )
    ]
    viewModel.statusText = "IPv6 网段已生成"
    viewModel.errorMessage = "error"
    viewModel.copyAllText = "copied"
    viewModel.primaryCopyText = "primary"

    viewModel.restore(
        direction: .ipv4ToIPv6,
        ipv4Input: "48.235.24.0/30",
        ipv6PrefixInput: "2001:db8::"
    )

    #expect(viewModel.direction == .ipv4ToIPv6)
    #expect(viewModel.ipv4Input == "48.235.24.0/30")
    #expect(viewModel.ipv6PrefixInput == "2001:db8::")
    #expect(viewModel.ipv6Input.isEmpty)
    #expect(viewModel.ipv6ReversePrefixInput.isEmpty)
    #expect(viewModel.resultSections.isEmpty)
    #expect(viewModel.statusText == "等待输入...")
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.copyAllText.isEmpty)
    #expect(viewModel.primaryCopyText.isEmpty)
    #expect(viewModel.primaryCopyLabel == "IPv6 网段")
}

@MainActor
@Test
func translationWorkspaceRestoreSupportsIpv6ToIpv4Direction() {
    let viewModel = TranslationWorkspaceViewModel()

    viewModel.restore(
        direction: .ipv6ToIPv4,
        ipv6Input: "2001:db8::30eb:1800/126",
        ipv6ReversePrefixInput: "2001:db8::"
    )

    #expect(viewModel.direction == .ipv6ToIPv4)
    #expect(viewModel.ipv4Input.isEmpty)
    #expect(viewModel.ipv6PrefixInput.isEmpty)
    #expect(viewModel.ipv6Input == "2001:db8::30eb:1800/126")
    #expect(viewModel.ipv6ReversePrefixInput == "2001:db8::")
    #expect(viewModel.primaryCopyLabel == "IPv4 网段")
}

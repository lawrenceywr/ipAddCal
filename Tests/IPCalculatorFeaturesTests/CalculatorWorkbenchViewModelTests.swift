import IPCalculatorCore
import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func workbenchWritesHistoryOnlyForManualIpCalculations() {
    let workbench = CalculatorWorkbenchViewModel()
    workbench.networkWorkspace.networkInput = "192.168.1.10/24"

    workbench.calculateCurrentIPWorkspace()
    #expect(workbench.history.entries.count == 1)

    workbench.navigation.selectedWorkspace = .baseConversion
    workbench.networkWorkspace.networkInput = "10.0.0.1/24"
    workbench.calculateCurrentIPWorkspace()
    #expect(workbench.history.entries.count == 1)
}

@MainActor
@Test
func workbenchRestoresTranslationHistoryIntoTheCorrectWorkspace() {
    let workbench = CalculatorWorkbenchViewModel()
    let entry = HistoryEntry(
        title: "2001:db8::30eb:1800/126",
        subtitle: "V4 -> V6 · 48.235.24.0/30",
        copyText: "2001:db8::30eb:1800/126",
        restoreTarget: .ipv4ToIPv6(ipv4Input: "48.235.24.0/30", ipv6PrefixInput: "2001:db8::")
    )

    workbench.restore(entry)

    #expect(workbench.navigation.selectedWorkspace == .ipCalculation)
    #expect(workbench.navigation.selectedIPMode == .translation)
    #expect(workbench.navigation.isHistoryPresented == false)
    #expect(workbench.translationWorkspace.direction == .ipv4ToIPv6)
    #expect(workbench.translationWorkspace.ipv4Input == "48.235.24.0/30")
    #expect(workbench.translationWorkspace.ipv6PrefixInput == "2001:db8::")
}

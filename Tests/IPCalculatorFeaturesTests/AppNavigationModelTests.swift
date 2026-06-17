import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func navigationModelDefaultsToIPWorkspaceWithHistoryClosed() {
    let model = AppNavigationModel()

    #expect(model.selectedWorkspace == .ipCalculation)
    #expect(model.selectedIPMode == .network)
    #expect(model.isHistoryPresented == false)
}

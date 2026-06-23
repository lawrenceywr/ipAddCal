import Testing
@testable import IPNetworkCalculator

@Test
func defaultDarkThemeLocksConfirmedVisualDecisions() {
    let theme = CalculatorTheme.defaultDark

    #expect(theme.enforcesDarkAppearance == true)
    #expect(theme.accentMode == .macOSBlue)
    #expect(theme.glassIntensity == .elevated)
    #expect(theme.surfaceContrast == .clearBoundaries)
}

@Test
func defaultDarkThemeUsesGraphiteSurfaceHierarchy() {
    let theme = CalculatorTheme.defaultDark
    let workspace = theme.workspaceSurface
    let popover = theme.popoverSurface

    #expect(workspace.cornerRadius == 20)
    #expect(workspace.fillOpacity == 0.78)
    #expect(workspace.strokeOpacity == 0.18)
    #expect(workspace.highlightOpacity == 0.24)
    #expect(workspace.shadowOpacity == 0.22)
    #expect(popover.cornerRadius == 18)
    #expect(popover.fillOpacity == 0.86)
    #expect(popover.strokeOpacity == 0.16)
    #expect(popover.highlightOpacity == 0.28)
    #expect(popover.shadowOpacity == 0.24)
}

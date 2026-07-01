import Foundation
import Testing
@testable import IPNetworkCalculator

@Test
func defaultDarkThemeLocksConfirmedVisualDecisions() {
    let theme = CalculatorTheme.defaultDark

    #expect(theme.enforcesDarkAppearance == true)
    #expect(theme.accentMode == .calculatorOrange)
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

@Test
func defaultDarkThemeDefinesChromeHierarchy() {
    let theme = CalculatorTheme.defaultDark

    #expect(theme.chrome.sidebarFillOpacity == 0.96)
    #expect(theme.chrome.detailFillOpacity == 0.92)
    #expect(theme.chrome.toolbarLineOpacity == 0.06)
    #expect(theme.chrome.detailFillOpacity < theme.chrome.sidebarFillOpacity)
    #expect(theme.workspaceSurface.fillOpacity < theme.popoverSurface.fillOpacity)
}

@Test
func defaultDarkThemeDefinesIntegratedSidebarAndToolbarChrome() {
    let chrome = CalculatorTheme.defaultDark.chrome

    #expect(chrome.sidebarFloatingCornerRadius == 0)
    #expect(chrome.sidebarRowCornerRadius == 10)
    #expect(chrome.titleItemBorderOpacity == 0)
    #expect(chrome.historyButtonHorizontalPadding == 16)
    #expect(chrome.historyButtonVerticalPadding == 8)
    #expect(chrome.historyButtonStrokeOpacity == 0.14)
    #expect(chrome.integratedSidebarWidth == 168)
    #expect(chrome.integratedSidebarDividerOpacity == 0.10)
}

@Test
func defaultDarkThemeDefinesReadableFieldChrome() {
    let field = CalculatorTheme.defaultDark.fieldChrome

    #expect(field.cornerRadius == 12)
    #expect(field.horizontalPadding == 12)
    #expect(field.verticalPadding == 10)
    #expect(field.fillOpacity == 0.92)
    #expect(field.strokeOpacity == 0.14)
    #expect(field.strokeWidth == 1)
    #expect(field.invalidStrokeWidth == 1.3)
}

@Test
func defaultDarkThemeDefinesReadableFormSurfaceChrome() {
    let surface = CalculatorTheme.defaultDark.formSurface

    #expect(surface.cornerRadius == 20)
    #expect(surface.fillOpacity == 0.78)
    #expect(surface.strokeOpacity == 0.18)
    #expect(surface.highlightOpacity == 0.24)
    #expect(surface.shadowOpacity == 0.22)
}

@Test
func defaultDarkThemeDefinesCustomResultSectionChrome() {
    let section = CalculatorTheme.defaultDark.resultSection

    #expect(section.cornerRadius == 16)
    #expect(section.horizontalPadding == 14)
    #expect(section.verticalPadding == 12)
    #expect(section.rowSpacing == 12)
    #expect(section.headerSpacing == 8)
    #expect(section.fillOpacity == 0.76)
    #expect(section.strokeOpacity == 0.12)
}

@Test
func darkThemeViewsUseSemanticErrorColor() throws {
    let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let targetRoot = packageRoot.appending(path: "Sources/IPNetworkCalculator")
    let sourceFiles = FileManager.default.enumerator(
        at: targetRoot,
        includingPropertiesForKeys: nil
    )?
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == "swift" } ?? []

    var directSystemRedUsages: [String] = []
    for sourceFile in sourceFiles {
        let source = try String(contentsOf: sourceFile, encoding: .utf8)
        if source.contains(".foregroundStyle(.red)") || source.contains("Color.red") {
            directSystemRedUsages.append(sourceFile.lastPathComponent)
        }
    }

    #expect(directSystemRedUsages.isEmpty)
}

@Test
func darkThemeSidebarUsesIntegratedCustomChrome() throws {
    let source = try sourceText(relativePath: "Sources/IPNetworkCalculator/SidebarNavigationView.swift")

    #expect(!source.contains("List("))
    #expect(!source.contains(".listStyle(.sidebar)"))
}

@Test
func darkThemeSidebarRowsExposeFullWidthHitTargets() throws {
    let source = try sourceText(relativePath: "Sources/IPNetworkCalculator/SidebarNavigationView.swift")

    #expect(source.contains(".contentShape(Rectangle())"))
}

@Test
func darkThemeRootLayoutDoesNotUseSystemSplitSidebarChrome() throws {
    let source = try sourceText(relativePath: "Sources/IPNetworkCalculator/ContentView.swift")

    #expect(!source.contains("NavigationSplitView"))
    #expect(source.contains("HStack(spacing: 0)"))
    #expect(source.contains("integratedSidebarWidth"))
    #expect(source.contains("integratedSidebarDividerOpacity"))
}

@Test
func darkThemeToolbarAvoidsPrincipalTitleCapsule() throws {
    let source = try sourceText(relativePath: "Sources/IPNetworkCalculator/ContentView.swift")

    #expect(!source.contains("placement: .principal"))
    #expect(!source.contains("placement: .navigation"))
    #expect(!source.contains(".navigationTitle("))
    #expect(source.contains("calculatorHistoryButtonChrome"))
}

@Test
func darkThemeToolbarAppliesHistoryChromeToButtonLabelOnly() throws {
    let source = try sourceText(relativePath: "Sources/IPNetworkCalculator/ContentView.swift")

    #expect(source.contains("Text(\"历史\")\n                        .calculatorHistoryButtonChrome()"))
    #expect(!source.contains("""
                    .buttonStyle(.plain)
                    .calculatorHistoryButtonChrome()
"""))
}

@Test
func ipInputFieldsUseNormalizingTextFieldForPunctuationAndReturnKey() throws {
    let networkSource = try sourceText(relativePath: "Sources/IPNetworkCalculator/NetworkWorkspaceView.swift")
    let translationSource = try sourceText(relativePath: "Sources/IPNetworkCalculator/TranslationWorkspaceView.swift")
    let normalizingSource = (try? sourceText(relativePath: "Sources/IPNetworkCalculator/NormalizingTextField.swift")) ?? ""

    #expect(networkSource.contains("NormalizingTextField("))
    #expect(translationSource.contains("NormalizingTextField("))
    #expect(normalizingSource.contains("InputNormalizer.normalizeFieldText"))
    #expect(normalizingSource.contains("controlTextDidChange"))
    #expect(normalizingSource.contains("insertNewline"))
    #expect(normalizingSource.contains("onSubmit()"))
}

private func sourceText(relativePath: String) throws -> String {
    let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    return try String(
        contentsOf: packageRoot.appending(path: relativePath),
        encoding: .utf8
    )
}

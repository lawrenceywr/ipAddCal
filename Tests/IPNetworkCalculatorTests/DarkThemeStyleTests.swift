import Foundation
import SwiftUI
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
func calculatorAppearanceDefaultsToDarkAndFallsBackFromInvalidStorage() {
    #expect(CalculatorAppearance.defaultValue == .dark)
    #expect(CalculatorAppearance(storedValue: nil) == .dark)
    #expect(CalculatorAppearance(storedValue: "light") == .light)
    #expect(CalculatorAppearance(storedValue: "unexpected") == .dark)
    #expect(CalculatorAppearance.storageKey == "calculatorAppearance")
}

@Test
func calculatorAppearanceMapsToColorSchemeThemeAndNextAction() {
    #expect(CalculatorAppearance.dark.colorScheme == .dark)
    #expect(CalculatorAppearance.dark.theme == .defaultDark)
    #expect(CalculatorAppearance.dark.toggled == .light)
    #expect(CalculatorAppearance.dark.toggleIconSystemName == "sun.max.fill")
    #expect(CalculatorAppearance.dark.toggleAccessibilityLabel == "切换到浅色模式")

    #expect(CalculatorAppearance.light.colorScheme == .light)
    #expect(CalculatorAppearance.light.theme == .defaultLight)
    #expect(CalculatorAppearance.light.toggled == .dark)
    #expect(CalculatorAppearance.light.toggleIconSystemName == "moon.fill")
    #expect(CalculatorAppearance.light.toggleAccessibilityLabel == "切换到深色模式")
}

@Test
func defaultLightThemeUsesCalculatorOrangeAndReadableLightSurfaces() {
    let light = CalculatorTheme.defaultLight
    let dark = CalculatorTheme.defaultDark

    #expect(light.enforcesDarkAppearance == false)
    #expect(light.accentMode == .calculatorOrange)
    #expect(light.accentMode == dark.accentMode)
    #expect(light.workspaceSurface.cornerRadius == dark.workspaceSurface.cornerRadius)
    #expect(light.formSurface.cornerRadius == dark.formSurface.cornerRadius)
    #expect(light.popoverSurface.cornerRadius == dark.popoverSurface.cornerRadius)
    #expect(light.resultSection.cornerRadius == dark.resultSection.cornerRadius)
    #expect(light.fieldChrome.cornerRadius == dark.fieldChrome.cornerRadius)
    #expect(light.chrome.integratedSidebarWidth == dark.chrome.integratedSidebarWidth)
    #expect(light.chrome.historyButtonHorizontalPadding == dark.chrome.historyButtonHorizontalPadding)
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
func appPersistsAndInjectsSelectedCalculatorAppearance() throws {
    let source = try sourceText(relativePath: "Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift")

    #expect(source.contains("@AppStorage(CalculatorAppearance.storageKey)"))
    #expect(source.contains("CalculatorAppearance(storedValue: appearanceRawValue)"))
    #expect(source.contains(".preferredColorScheme(selectedAppearance.colorScheme)"))
    #expect(source.contains(".calculatorTheme(selectedAppearance.theme)"))
}

@Test
func toolbarPlacesThemeToggleImmediatelyBeforeHistoryButton() throws {
    let source = try sourceText(relativePath: "Sources/IPNetworkCalculator/ContentView.swift")

    #expect(source.contains("Image(systemName: appearance.toggleIconSystemName)"))
    #expect(source.contains(".calculatorToolbarIconButtonChrome()"))
    #expect(source.contains("Text(\"历史\")\n                        .calculatorHistoryButtonChrome()"))

    let toggleIndex = try #require(source.range(of: "Image(systemName: appearance.toggleIconSystemName)"))
    let historyIndex = try #require(source.range(of: "Text(\"历史\")"))
    #expect(toggleIndex.lowerBound < historyIndex.lowerBound)
}

@Test
func appViewsDoNotHardCodeDefaultDarkThemeOutsideThemeDefinitions() throws {
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
        .filter { $0.pathExtension == "swift" && $0.lastPathComponent != "ThemeStyle.swift" } ?? []

    let offenders = try sourceFiles.filter { sourceFile in
        let source = try String(contentsOf: sourceFile, encoding: .utf8)
        return source.contains("CalculatorTheme.defaultDark")
    }
    .map(\.lastPathComponent)

    #expect(offenders.isEmpty)
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

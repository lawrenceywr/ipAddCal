# Manual Theme Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persisted manual dark/light appearance toggle beside the history button while keeping the calculator-orange chrome and current calculation behavior unchanged.

**Architecture:** Keep appearance state in the `IPNetworkCalculator` app target. Extend `CalculatorTheme` with explicit dark and light token sets, inject the active theme through SwiftUI environment, and make all view modifiers consume the injected theme instead of `CalculatorTheme.defaultDark`.

**Tech Stack:** Swift 6.2, SwiftUI, Swift Testing, Swift Package Manager, macOS 26.

---

## File Structure

- Modify: `Sources/IPNetworkCalculator/ThemeStyle.swift`
  - Add `CalculatorAppearance`, explicit color tokens for both themes, and a SwiftUI environment key.
- Modify: `Sources/IPNetworkCalculator/GlassStyle.swift`
  - Read `@Environment(\.calculatorTheme)` inside modifiers and add icon toolbar button chrome.
- Modify: `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`
  - Persist selected appearance with `@AppStorage` and inject the active theme.
- Modify: `Sources/IPNetworkCalculator/ContentView.swift`
  - Accept appearance toggle dependencies, place the toggle immediately before `历史`, and use injected theme.
- Modify: `Sources/IPNetworkCalculator/SidebarNavigationView.swift`
  - Use injected theme and keep full-width row hit targets.
- Modify: `Sources/IPNetworkCalculator/IPWorkspacePickerView.swift`
- Modify: `Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift`
- Modify: `Sources/IPNetworkCalculator/NetworkWorkspaceView.swift`
- Modify: `Sources/IPNetworkCalculator/TranslationWorkspaceView.swift`
- Modify: `Sources/IPNetworkCalculator/BaseConversionView.swift`
- Modify: `Sources/IPNetworkCalculator/BinaryBitGridView.swift`
- Modify: `Sources/IPNetworkCalculator/ResultPanelView.swift`
- Modify: `Sources/IPNetworkCalculator/HistoryPopoverView.swift`
  - Replace direct `CalculatorTheme.defaultDark` and hard-coded white styling with semantic theme values.
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`
  - Add appearance, light-theme, toolbar-toggle, and source-regression tests.

### Task 1: Lock Appearance and Light Theme Behavior

**Files:**
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`
- Modify: `Sources/IPNetworkCalculator/ThemeStyle.swift`

- [ ] **Step 1: Add failing tests for manual appearance state**

Add these tests above the source-level tests in `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the targeted tests to verify RED**

Run:

```bash
swift test --filter "calculatorAppearance|defaultLightTheme"
```

Expected: FAIL with compiler errors for `CalculatorAppearance` and `CalculatorTheme.defaultLight`.

- [ ] **Step 3: Implement `CalculatorAppearance`, explicit light tokens, and theme environment**

In `Sources/IPNetworkCalculator/ThemeStyle.swift`, update `CalculatorTheme` so base colors are constructor fields, add `defaultLight`, then add:

```swift
enum CalculatorAppearance: String, Equatable, CaseIterable, Identifiable {
    case dark
    case light

    static let storageKey = "calculatorAppearance"
    static let defaultValue: CalculatorAppearance = .dark

    var id: String { rawValue }

    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? Self.defaultValue
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }

    var theme: CalculatorTheme {
        switch self {
        case .dark: return .defaultDark
        case .light: return .defaultLight
        }
    }

    var toggled: CalculatorAppearance {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }

    var toggleIconSystemName: String {
        switch self {
        case .dark: return "sun.max.fill"
        case .light: return "moon.fill"
        }
    }

    var toggleAccessibilityLabel: String {
        switch self {
        case .dark: return "切换到浅色模式"
        case .light: return "切换到深色模式"
        }
    }
}

private struct CalculatorThemeKey: EnvironmentKey {
    static let defaultValue = CalculatorTheme.defaultDark
}

extension EnvironmentValues {
    var calculatorTheme: CalculatorTheme {
        get { self[CalculatorThemeKey.self] }
        set { self[CalculatorThemeKey.self] = newValue }
    }
}

extension View {
    func calculatorTheme(_ theme: CalculatorTheme) -> some View {
        environment(\.calculatorTheme, theme)
    }
}
```

- [ ] **Step 4: Run the targeted tests to verify GREEN**

Run:

```bash
swift test --filter "calculatorAppearance|defaultLightTheme"
```

Expected: PASS for the three new tests.

### Task 2: Wire Persisted Appearance and Toolbar Toggle

**Files:**
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`
- Modify: `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`
- Modify: `Sources/IPNetworkCalculator/ContentView.swift`
- Modify: `Sources/IPNetworkCalculator/GlassStyle.swift`

- [ ] **Step 1: Add failing source-regression tests for the app wiring and toolbar placement**

Add:

```swift
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
    #expect(source.range(of: "Image(systemName: appearance.toggleIconSystemName)")!.lowerBound < source.range(of: "Text(\"历史\")")!.lowerBound)
}
```

- [ ] **Step 2: Run targeted tests to verify RED**

Run:

```bash
swift test --filter "appPersists|toolbarPlacesThemeToggle"
```

Expected: FAIL because the app does not persist `CalculatorAppearance` yet and `ContentView` has no theme toggle.

- [ ] **Step 3: Implement app persistence and toolbar toggle**

Use this shape:

```swift
@main
struct IPNetworkCalculatorApp: App {
    @NSApplicationDelegateAdaptor(AppActivationDelegate.self) private var appActivationDelegate
    @AppStorage(CalculatorAppearance.storageKey) private var appearanceRawValue = CalculatorAppearance.defaultValue.rawValue

    private var selectedAppearance: CalculatorAppearance {
        CalculatorAppearance(storedValue: appearanceRawValue)
    }

    var body: some Scene {
        WindowGroup("IP 地址计算器") {
            ContentView(
                appearance: selectedAppearance,
                onToggleAppearance: {
                    appearanceRawValue = selectedAppearance.toggled.rawValue
                }
            )
            .frame(minWidth: 980, minHeight: 640)
            .preferredColorScheme(selectedAppearance.colorScheme)
            .tint(selectedAppearance.theme.accentMode.tint)
            .calculatorTheme(selectedAppearance.theme)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
```

In `ContentView`, add `let appearance: CalculatorAppearance` and `let onToggleAppearance: () -> Void`, then add the icon button immediately before the history button in the existing toolbar item group.

In `GlassStyle.swift`, add `calculatorToolbarIconButtonChrome()` as a circular/square icon-button modifier using the injected theme.

- [ ] **Step 4: Run targeted tests to verify GREEN**

Run:

```bash
swift test --filter "appPersists|toolbarPlacesThemeToggle"
```

Expected: PASS.

### Task 3: Migrate Views to Injected Theme

**Files:**
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`
- Modify all `Sources/IPNetworkCalculator/*.swift` files that currently reference `CalculatorTheme.defaultDark`

- [ ] **Step 1: Add a failing source-regression test for hard-coded dark references**

Add:

```swift
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
```

- [ ] **Step 2: Run the source-regression test to verify RED**

Run:

```bash
swift test --filter appViewsDoNotHardCodeDefaultDarkThemeOutsideThemeDefinitions
```

Expected: FAIL and list files such as `GlassStyle.swift`, `ContentView.swift`, and workspace views.

- [ ] **Step 3: Replace hard-coded theme references**

For each SwiftUI view or modifier, add:

```swift
@Environment(\.calculatorTheme) private var theme
```

Then replace:

- `private let theme = CalculatorTheme.defaultDark`
- `CalculatorTheme.defaultDark.secondaryLabel`
- `CalculatorTheme.defaultDark.error`
- `.tint(CalculatorTheme.defaultDark.accentMode.tint)`
- hard-coded `.white` text where the color should follow theme foreground

with the injected `theme` and semantic theme colors.

- [ ] **Step 4: Run the source-regression test to verify GREEN**

Run:

```bash
swift test --filter appViewsDoNotHardCodeDefaultDarkThemeOutsideThemeDefinitions
```

Expected: PASS.

### Task 4: Verify the Whole App

**Files:**
- All modified files

- [ ] **Step 1: Run the focused UI/theme test group**

Run:

```bash
swift test --filter IPNetworkCalculatorTests
```

Expected: PASS.

- [ ] **Step 2: Run the full test suite**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 3: Run the app for visual smoke**

Run:

```bash
swift run IPNetworkCalculator
```

Expected: app launches. Check dark mode, click the theme toggle beside `历史`, confirm light mode appears, switch back, and confirm IP calculation, IPv4/IPv6 translation, base conversion, sidebar rows, and history popover still behave.

- [ ] **Step 4: Commit implementation**

Stage only tracked implementation files and the plan:

```bash
git add docs/superpowers/plans/2026-07-02-manual-theme-toggle.md Sources/IPNetworkCalculator/ThemeStyle.swift Sources/IPNetworkCalculator/GlassStyle.swift Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift Sources/IPNetworkCalculator/ContentView.swift Sources/IPNetworkCalculator/SidebarNavigationView.swift Sources/IPNetworkCalculator/IPWorkspacePickerView.swift Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift Sources/IPNetworkCalculator/NetworkWorkspaceView.swift Sources/IPNetworkCalculator/TranslationWorkspaceView.swift Sources/IPNetworkCalculator/BaseConversionView.swift Sources/IPNetworkCalculator/BinaryBitGridView.swift Sources/IPNetworkCalculator/ResultPanelView.swift Sources/IPNetworkCalculator/HistoryPopoverView.swift Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift
git commit -m "feat: add manual theme toggle"
```

## Self-Review

- Spec coverage: the plan covers manual-only appearance, dark default, persistence, adjacent toolbar toggle, orange accent continuity, light theme tokens, injected theme usage, sidebar/history chrome protections, and verification.
- Placeholder scan: no unresolved marker or unspecified implementation slots remain.
- Type consistency: all tasks use `CalculatorAppearance`, `CalculatorTheme.defaultLight`, `calculatorTheme(_:)`, and `calculatorToolbarIconButtonChrome()` consistently.

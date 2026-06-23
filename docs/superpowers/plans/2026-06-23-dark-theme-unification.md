# Dark Theme Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current light-material SwiftUI styling with a fixed, system-calculator-inspired deep dark theme across the entire macOS app without changing any calculation behavior.

**Architecture:** Add centralized dark-theme tokens and semantic surface/control modifiers inside the `IPNetworkCalculator` target, then apply them from the app root through chrome, workspaces, result sections, and the history popover. Keep all theme state out of `IPCalculatorCore` and `IPCalculatorFeatures`, and use testable style structs to lock the confirmed visual decisions before wiring SwiftUI views.

**Tech Stack:** Swift 6.2, SwiftUI, AppKit (only for appearance fallback if required), Swift Testing, Swift Package Manager, macOS 26.

---

## File Structure

- Create: `Sources/IPNetworkCalculator/ThemeStyle.swift`
  - Hold the fixed dark-theme configuration, semantic palette tokens, surface metrics, and testable style structs.
- Modify: `Sources/IPNetworkCalculator/GlassStyle.swift`
  - Rebuild workspace/popover/chrome modifiers on top of the new dark-theme tokens.
- Modify: `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`
  - Enforce dark appearance at the app/root level and apply the shared accent tint.
- Modify: `Sources/IPNetworkCalculator/ContentView.swift`
  - Apply the root dark background, toolbar chrome, and split-view detail hierarchy.
- Modify: `Sources/IPNetworkCalculator/SidebarNavigationView.swift`
  - Hide default light list background, apply dark sidebar chrome, and preserve blue selection.
- Modify: `Sources/IPNetworkCalculator/IPWorkspacePickerView.swift`
  - Apply theme-aware segmented control tint and hierarchy.
- Modify: `Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift`
  - Apply the same segmented control styling as the IP workspace picker.
- Modify: `Sources/IPNetworkCalculator/NetworkWorkspaceView.swift`
  - Replace default text-field styling with dark field chrome and align buttons/helper text with the theme.
- Modify: `Sources/IPNetworkCalculator/TranslationWorkspaceView.swift`
  - Apply the same dark field and button styling to both translation flows.
- Modify: `Sources/IPNetworkCalculator/BaseConversionView.swift`
  - Keep the current layout but restyle surfaces and fields to match the dark theme.
- Modify: `Sources/IPNetworkCalculator/BinaryBitGridView.swift`
  - Integrate the existing compact bit grid into the dark palette without reworking its layout.
- Modify: `Sources/IPNetworkCalculator/ResultPanelView.swift`
  - Replace `GroupBox` with app-owned dark section chrome while preserving copy behavior and result structure.
- Modify: `Sources/IPNetworkCalculator/HistoryPopoverView.swift`
  - Restyle the popover body, buttons, and dividers for the dark theme.
- Create: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`
  - Lock the fixed dark-theme decisions and style metrics with testable configuration assertions.

### Task 1: Add Centralized Dark Theme Tokens

**Files:**
- Create: `Sources/IPNetworkCalculator/ThemeStyle.swift`
- Create: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

- [ ] **Step 1: Write the failing tests for the fixed dark-theme decisions**

```swift
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
    #expect(workspace.strokeOpacity == 0.18)
    #expect(workspace.highlightOpacity == 0.24)
    #expect(workspace.shadowOpacity == 0.22)
    #expect(popover.cornerRadius == 18)
    #expect(popover.fillOpacity > workspace.fillOpacity)
}
```

- [ ] **Step 2: Run the targeted tests to verify the types do not exist yet**

Run:

```bash
swift test --filter DarkThemeStyleTests
```

Expected: FAIL with compiler errors for `CalculatorTheme`, `accentMode`, `glassIntensity`, `surfaceContrast`, and `workspaceSurface`.

- [ ] **Step 3: Add the theme configuration types and semantic palette**

```swift
// Sources/IPNetworkCalculator/ThemeStyle.swift
import SwiftUI

enum ThemeAccentMode: Equatable {
    case macOSBlue

    var tint: Color { .blue }
}

enum ThemeGlassIntensity: Equatable {
    case elevated
}

enum ThemeSurfaceContrast: Equatable {
    case clearBoundaries
}

struct CalculatorSurfaceStyle: Equatable {
    var cornerRadius: CGFloat
    var fillOpacity: Double
    var strokeOpacity: Double
    var highlightOpacity: Double
    var shadowOpacity: Double
}

struct CalculatorTheme: Equatable {
    var enforcesDarkAppearance: Bool
    var accentMode: ThemeAccentMode
    var glassIntensity: ThemeGlassIntensity
    var surfaceContrast: ThemeSurfaceContrast
    var windowBase = Color(red: 0.115, green: 0.121, blue: 0.139)
    var chromeBase = Color(red: 0.148, green: 0.156, blue: 0.178)
    var chromeElevated = Color(red: 0.178, green: 0.186, blue: 0.212)
    var contentBase = Color(red: 0.205, green: 0.214, blue: 0.244)
    var divider = Color.white.opacity(0.10)
    var secondaryLabel = Color.white.opacity(0.64)
    var error = Color(red: 0.93, green: 0.42, blue: 0.42)
    var workspaceSurface: CalculatorSurfaceStyle
    var popoverSurface: CalculatorSurfaceStyle

    static let defaultDark = CalculatorTheme(
        enforcesDarkAppearance: true,
        accentMode: .macOSBlue,
        glassIntensity: .elevated,
        surfaceContrast: .clearBoundaries,
        workspaceSurface: CalculatorSurfaceStyle(
            cornerRadius: 20,
            fillOpacity: 0.78,
            strokeOpacity: 0.18,
            highlightOpacity: 0.24,
            shadowOpacity: 0.22
        ),
        popoverSurface: CalculatorSurfaceStyle(
            cornerRadius: 18,
            fillOpacity: 0.86,
            strokeOpacity: 0.16,
            highlightOpacity: 0.28,
            shadowOpacity: 0.24
        )
    )
}
```

- [ ] **Step 4: Run the targeted tests to verify the style model passes**

Run:

```bash
swift test --filter DarkThemeStyleTests
```

Expected: PASS with `defaultDarkThemeLocksConfirmedVisualDecisions` and `defaultDarkThemeUsesGraphiteSurfaceHierarchy`.

- [ ] **Step 5: Commit the theme-token foundation**

```bash
git add Sources/IPNetworkCalculator/ThemeStyle.swift Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift
git commit -m "style: add dark theme tokens"
```

### Task 2: Apply Dark Appearance to App Chrome

**Files:**
- Modify: `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`
- Modify: `Sources/IPNetworkCalculator/ContentView.swift`
- Modify: `Sources/IPNetworkCalculator/SidebarNavigationView.swift`
- Modify: `Sources/IPNetworkCalculator/GlassStyle.swift`
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

- [ ] **Step 1: Extend the tests with chrome-specific expectations**

```swift
@Test
func defaultDarkThemeDefinesChromeHierarchy() {
    let theme = CalculatorTheme.defaultDark

    #expect(theme.chrome.sidebarFillOpacity == 0.96)
    #expect(theme.chrome.toolbarLineOpacity == 0.06)
    #expect(theme.workspaceSurface.fillOpacity < theme.popoverSurface.fillOpacity)
}
```

- [ ] **Step 2: Run the targeted tests to confirm the new chrome properties are not available**

Run:

```bash
swift test --filter defaultDarkThemeDefinesChromeHierarchy
```

Expected: FAIL because the `chrome` style is not defined on `CalculatorTheme`.

- [ ] **Step 3: Rebuild the root app shell around the dark theme**

```swift
// Sources/IPNetworkCalculator/ThemeStyle.swift
struct CalculatorChromeStyle: Equatable {
    var sidebarFillOpacity: Double
    var toolbarLineOpacity: Double
}

extension CalculatorTheme {
    var chrome: CalculatorChromeStyle {
        CalculatorChromeStyle(
            sidebarFillOpacity: 0.96,
            toolbarLineOpacity: 0.06
        )
    }
}

// Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift
@main
struct IPNetworkCalculatorApp: App {
    @NSApplicationDelegateAdaptor(AppActivationDelegate.self) private var appActivationDelegate
    private let theme = CalculatorTheme.defaultDark

    var body: some Scene {
        WindowGroup("IP 地址计算器") {
            ContentView()
                .frame(minWidth: 980, minHeight: 640)
                .preferredColorScheme(theme.enforcesDarkAppearance ? .dark : nil)
                .tint(theme.accentMode.tint)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

// Sources/IPNetworkCalculator/GlassStyle.swift
private let theme = CalculatorTheme.defaultDark

private struct ChromeBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(theme.chromeBase.opacity(theme.chrome.sidebarFillOpacity))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(theme.chrome.toolbarLineOpacity))
                    .frame(height: 1)
            }
    }
}

extension View {
    func calculatorChromeBackground() -> some View {
        modifier(ChromeBackgroundModifier())
    }
}

// Sources/IPNetworkCalculator/ContentView.swift
struct ContentView: View {
    @State private var workbench = CalculatorWorkbenchViewModel()
    private let theme = CalculatorTheme.defaultDark

    var body: some View {
        @Bindable var workbench = workbench

        NavigationSplitView {
            SidebarNavigationView(selection: $workbench.navigation.selectedWorkspace)
                .calculatorChromeBackground()
        } detail: {
            Group {
                switch workbench.navigation.selectedWorkspace {
                case .ipCalculation:
                    IPWorkspaceView(workbench: workbench)
                case .baseConversion:
                    BaseConversionView(viewModel: workbench.baseConversionWorkspace)
                }
            }
            .padding(WorkspaceChrome.contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(theme.windowBase.gradient)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(workbench.windowTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.94))
                }

                ToolbarItem {
                    Button("历史") {
                        workbench.navigation.isHistoryPresented.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .popover(isPresented: $workbench.navigation.isHistoryPresented) {
                        HistoryPopoverView(
                            entries: workbench.history.entries,
                            onRestore: { entry in
                                workbench.restore(entry)
                            }
                        )
                    }
                }
            }
        }
    }
}

// Sources/IPNetworkCalculator/SidebarNavigationView.swift
struct SidebarNavigationView: View {
    @Binding var selection: AppWorkspace

    var body: some View {
        List(AppWorkspace.allCases, selection: listSelection) { workspace in
            Text(workspace.title)
                .foregroundStyle(.white.opacity(0.92))
                .tag(workspace)
        }
        .scrollContentBackground(.hidden)
        .background(CalculatorTheme.defaultDark.chromeBase)
        .listStyle(.sidebar)
    }
}
```

- [ ] **Step 4: Run the targeted tests and a smoke launch**

Run:

```bash
swift test --filter DarkThemeStyleTests
swift run IPNetworkCalculator
```

Expected:

- `DarkThemeStyleTests` PASS
- app builds and launches with a dark root appearance

- [ ] **Step 5: Commit the dark app chrome**

```bash
git add Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift Sources/IPNetworkCalculator/ContentView.swift Sources/IPNetworkCalculator/SidebarNavigationView.swift Sources/IPNetworkCalculator/GlassStyle.swift Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift
git commit -m "style: apply dark app chrome"
```

### Task 3: Restyle Workspace Surfaces and Controls

**Files:**
- Modify: `Sources/IPNetworkCalculator/GlassStyle.swift`
- Modify: `Sources/IPNetworkCalculator/IPWorkspacePickerView.swift`
- Modify: `Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift`
- Modify: `Sources/IPNetworkCalculator/NetworkWorkspaceView.swift`
- Modify: `Sources/IPNetworkCalculator/TranslationWorkspaceView.swift`
- Modify: `Sources/IPNetworkCalculator/BaseConversionView.swift`
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

- [ ] **Step 1: Add failing tests for dark field and control metrics**

```swift
@Test
func defaultDarkThemeDefinesReadableFieldChrome() {
    let field = CalculatorTheme.defaultDark.fieldChrome

    #expect(field.cornerRadius == 12)
    #expect(field.horizontalPadding == 12)
    #expect(field.verticalPadding == 10)
    #expect(field.strokeOpacity == 0.14)
}
```

- [ ] **Step 2: Run the targeted test to verify the field style does not exist yet**

Run:

```bash
swift test --filter defaultDarkThemeDefinesReadableFieldChrome
```

Expected: FAIL because `fieldChrome` is not defined on `CalculatorTheme`.

- [ ] **Step 3: Add reusable dark field/control modifiers and apply them across workspaces**

```swift
// Sources/IPNetworkCalculator/ThemeStyle.swift
struct CalculatorFieldChrome: Equatable {
    var cornerRadius: CGFloat
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat
    var strokeOpacity: Double
}

extension CalculatorTheme {
    var fieldChrome: CalculatorFieldChrome {
        CalculatorFieldChrome(
            cornerRadius: 12,
            horizontalPadding: 12,
            verticalPadding: 10,
            strokeOpacity: 0.14
        )
    }
}

// Sources/IPNetworkCalculator/GlassStyle.swift
private struct CalculatorFieldModifier: ViewModifier {
    var invalid: Bool

    func body(content: Content) -> some View {
        let theme = CalculatorTheme.defaultDark
        let field = theme.fieldChrome

        content
            .padding(.horizontal, field.horizontalPadding)
            .padding(.vertical, field.verticalPadding)
            .background(theme.chromeElevated.opacity(0.92), in: RoundedRectangle(cornerRadius: field.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: field.cornerRadius, style: .continuous)
                    .stroke(
                        invalid ? theme.error : .white.opacity(field.strokeOpacity),
                        lineWidth: invalid ? 1.3 : 1
                    )
            }
    }
}

extension View {
    func calculatorFieldChrome(invalid: Bool = false) -> some View {
        modifier(CalculatorFieldModifier(invalid: invalid))
    }
}

// Sources/IPNetworkCalculator/NetworkWorkspaceView.swift
private func field(_ title: String, example: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: WorkspaceChrome.fieldLabelSpacing) {
        Text(title).font(.subheadline.weight(.semibold))
        Text(example)
            .font(.footnote)
            .foregroundStyle(CalculatorTheme.defaultDark.secondaryLabel)
        TextField(title, text: normalizedBinding(text))
            .font(.system(.body, design: .monospaced))
            .textFieldStyle(.plain)
            .calculatorFieldChrome()
    }
}

// Sources/IPNetworkCalculator/TranslationWorkspaceView.swift
private func field(_ title: String, example: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: WorkspaceChrome.fieldLabelSpacing) {
        Text(title).font(.subheadline.weight(.semibold))
        Text(example)
            .font(.footnote)
            .foregroundStyle(CalculatorTheme.defaultDark.secondaryLabel)
        TextField(title, text: normalizedBinding(text))
            .font(.system(.body, design: .monospaced))
            .textFieldStyle(.plain)
            .calculatorFieldChrome()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

// Sources/IPNetworkCalculator/BaseConversionView.swift
private func baseField(_ title: String, text: String, base: NumberBase) -> some View {
    VStack(alignment: .leading, spacing: WorkspaceChrome.fieldLabelSpacing) {
        Text(title).font(.subheadline.weight(.semibold))
        TextField(title, text: Binding(
            get: { text },
            set: { newValue in viewModel.update(text: newValue, base: base) }
        ))
        .font(.system(.body, design: .monospaced))
        .textFieldStyle(.plain)
        .calculatorFieldChrome(invalid: viewModel.invalidBase == base)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

// Sources/IPNetworkCalculator/IPWorkspacePickerView.swift
Picker("IP 工作区", selection: $selection) {
    ForEach(IPWorkspaceMode.allCases) { mode in
        Text(mode.title).tag(mode)
    }
}
.pickerStyle(.segmented)
.controlSize(.large)
.tint(CalculatorTheme.defaultDark.accentMode.tint)

// Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift
Picker("互转方向", selection: $selection) {
    ForEach(TranslationDirection.allCases) { direction in
        Text(direction.title).tag(direction)
    }
}
.pickerStyle(.segmented)
.controlSize(.large)
.tint(CalculatorTheme.defaultDark.accentMode.tint)
```

- [ ] **Step 4: Run the targeted tests and the full suite**

Run:

```bash
swift test --filter DarkThemeStyleTests
swift test
```

Expected:

- `defaultDarkThemeDefinesReadableFieldChrome` PASS
- full suite PASS with no behavior regressions

- [ ] **Step 5: Commit the dark workspace controls**

```bash
git add Sources/IPNetworkCalculator/ThemeStyle.swift Sources/IPNetworkCalculator/GlassStyle.swift Sources/IPNetworkCalculator/IPWorkspacePickerView.swift Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift Sources/IPNetworkCalculator/NetworkWorkspaceView.swift Sources/IPNetworkCalculator/TranslationWorkspaceView.swift Sources/IPNetworkCalculator/BaseConversionView.swift Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift
git commit -m "style: restyle dark workspace controls"
```

### Task 4: Replace Result and Popover Chrome, Then Integrate the Binary Grid

**Files:**
- Modify: `Sources/IPNetworkCalculator/ResultPanelView.swift`
- Modify: `Sources/IPNetworkCalculator/HistoryPopoverView.swift`
- Modify: `Sources/IPNetworkCalculator/BinaryBitGridView.swift`
- Modify: `Sources/IPNetworkCalculator/GlassStyle.swift`
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

- [ ] **Step 1: Add failing tests for custom result-section chrome**

```swift
@Test
func defaultDarkThemeDefinesCustomResultSectionChrome() {
    let section = CalculatorTheme.defaultDark.resultSection

    #expect(section.cornerRadius == 16)
    #expect(section.rowSpacing == 12)
    #expect(section.headerSpacing == 8)
}
```

- [ ] **Step 2: Run the targeted tests to verify the result-section style does not exist yet**

Run:

```bash
swift test --filter defaultDarkThemeDefinesCustomResultSectionChrome
```

Expected: FAIL because `resultSection` is not defined on `CalculatorTheme`.

- [ ] **Step 3: Replace default `GroupBox` chrome with app-owned dark section containers and align the popover/grid styling**

```swift
// Sources/IPNetworkCalculator/ThemeStyle.swift
struct CalculatorSectionChrome: Equatable {
    var cornerRadius: CGFloat
    var rowSpacing: CGFloat
    var headerSpacing: CGFloat
}

extension CalculatorTheme {
    var resultSection: CalculatorSectionChrome {
        CalculatorSectionChrome(cornerRadius: 16, rowSpacing: 12, headerSpacing: 8)
    }
}

// Sources/IPNetworkCalculator/ResultPanelView.swift
private let theme = CalculatorTheme.defaultDark

var body: some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Text(feedback.isEmpty ? statusText : feedback)
                .font(.headline)
                .foregroundStyle(errorMessage == nil ? Color.white.opacity(0.94) : theme.error)
            Spacer()
            if !primaryCopyText.isEmpty {
                Button("复制 \(primaryCopyLabel)") {
                    ClipboardService.copy(primaryCopyText)
                    flash("已复制：\(primaryCopyLabel)")
                }
                .controlSize(.small)
            }
            if !copyAllText.isEmpty {
                Button("复制全部") {
                    ClipboardService.copy(copyAllText)
                    flash("已复制：全部结果")
                }
                .controlSize(.small)
            }
        }

        if let errorMessage {
            Text(errorMessage).foregroundStyle(theme.error)
        } else if sections.isEmpty {
            Text("暂无结果").foregroundStyle(theme.secondaryLabel)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: theme.resultSection.headerSpacing) {
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.88))

                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                            ForEach(section.rows) { row in
                                GridRow {
                                    Text(row.label).foregroundStyle(theme.secondaryLabel)
                                    Button {
                                        ClipboardService.copy(row.value)
                                        flash("已复制：\(row.label)")
                                    } label: {
                                        Text(row.value)
                                            .font(.system(.body, design: .monospaced).bold())
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                    .help("复制\(row.label)")
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(theme.chromeElevated.opacity(0.82), in: RoundedRectangle(cornerRadius: theme.resultSection.cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: theme.resultSection.cornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
                }
            }
        }
    }
    .padding(WorkspaceChrome.surfacePadding)
    .calculatorWorkspaceSurface()
}

// Sources/IPNetworkCalculator/HistoryPopoverView.swift
var body: some View {
    VStack(alignment: .leading, spacing: 14) {
        Text("历史记录")
            .font(.headline)
            .foregroundStyle(.white.opacity(0.94))

        if entries.isEmpty {
            Text("暂无历史记录")
                .foregroundStyle(CalculatorTheme.defaultDark.secondaryLabel)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.title)
                                .font(.system(.body, design: .monospaced).bold())
                                .foregroundStyle(.white.opacity(0.92))
                                .textSelection(.enabled)

                            Text(entry.subtitle)
                                .font(.caption)
                                .foregroundStyle(CalculatorTheme.defaultDark.secondaryLabel)

                            HStack(spacing: 8) {
                                Button(copiedEntryID == entry.id ? "已复制" : "复制") {
                                    copy(entry)
                                }

                                Button("恢复") {
                                    onRestore(entry)
                                }
                                .disabled(entry.restoreTarget == nil)
                            }
                            .controlSize(.small)
                        }

                        if entry.id != entries.last?.id {
                            Divider()
                                .overlay(CalculatorTheme.defaultDark.divider)
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
        }
    }
    .padding(WorkspaceChrome.surfacePadding)
    .frame(width: 360, alignment: .leading)
    .calculatorPopoverSurface()
}

// Sources/IPNetworkCalculator/BinaryBitGridView.swift
Button(String(cell.character)) {
    onToggle(cell.bitIndex)
}
.font(.system(size: 12, weight: .semibold, design: .monospaced))
.frame(width: 22, height: 22)
.buttonStyle(.bordered)
.controlSize(.small)
.tint(.white.opacity(0.18))
```

- [ ] **Step 4: Run the targeted tests, full suite, and app smoke**

Run:

```bash
swift test --filter DarkThemeStyleTests
swift test
swift run IPNetworkCalculator
```

Expected:

- `defaultDarkThemeDefinesCustomResultSectionChrome` PASS
- full suite PASS
- app builds and launches with dark result sections, dark history popover, and integrated binary-grid styling

- [ ] **Step 5: Commit the result/popover/binary styling**

```bash
git add Sources/IPNetworkCalculator/ThemeStyle.swift Sources/IPNetworkCalculator/GlassStyle.swift Sources/IPNetworkCalculator/ResultPanelView.swift Sources/IPNetworkCalculator/HistoryPopoverView.swift Sources/IPNetworkCalculator/BinaryBitGridView.swift Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift
git commit -m "style: complete dark theme unification"
```

## Self-Review

- **Spec coverage:** The plan covers fixed dark appearance, blue accent retention, stronger glass, clear panel boundaries, dark sidebar/toolbar chrome, dark workspace surfaces, dark controls, custom result section styling, history popover restyling, and binary-grid integration.
- **Placeholder scan:** No task uses TODO/TBD wording, every code step includes concrete code, and every verification step includes exact commands and expected outcomes.
- **Type consistency:** The plan defines `CalculatorTheme` before later tasks extend it with `fieldChrome` and `resultSection`. All later tasks use the same `CalculatorTheme.defaultDark` entry point and the same property names introduced earlier.

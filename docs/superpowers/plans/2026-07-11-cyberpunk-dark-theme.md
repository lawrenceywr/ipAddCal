# Cyberpunk Dark Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace only the calculator's dark appearance with the approved Neon Tactical Cyberpunk system while preserving the current light appearance and all calculator behavior.

**Architecture:** Extend `CalculatorTheme` with a visual-style discriminator and semantic neon tokens, then route the existing shared surface modifiers through that style. Add one focused SwiftUI file for chamfered geometry, terminal headers, backgrounds, and reusable button chrome; existing workspaces opt into these components without changing view-model bindings.

**Tech Stack:** Swift 6.2, SwiftUI, macOS 26+, Swift Testing, Swift Package Manager.

## Global Constraints

- Only `CalculatorTheme.defaultDark` uses Neon Tactical; `defaultLight` keeps its current classic glass values and geometry.
- Do not modify calculation, normalization, conversion, history, persistence, copy, or navigation model behavior.
- Do not add external fonts, images, packages, or network dependencies.
- Preserve the current system toolbar controls and the Return-to-calculate shortcut.
- Respect `accessibilityReduceMotion`; decorative overlays must ignore hit testing.
- Preserve all pre-existing uncommitted workspace changes. Because those changes overlap the implementation files, implementation checkpoints use diffs and tests instead of commits; the user can choose final staging scope later.

---

## File Map

- Create `Sources/IPNetworkCalculator/CyberpunkStyle.swift`: chamfered geometry, workspace background, terminal header, and reusable Cyberpunk control modifiers.
- Modify `Sources/IPNetworkCalculator/ThemeStyle.swift`: visual-style enum and centralized neon tokens.
- Modify `Sources/IPNetworkCalculator/GlassStyle.swift`: style-aware surfaces and fields.
- Modify `Sources/IPNetworkCalculator/ContentView.swift`: dark workspace background and scanline composition without toolbar changes.
- Modify `Sources/IPNetworkCalculator/SidebarNavigationView.swift`: semantic Neon Tactical row styling and telemetry decoration.
- Modify `Sources/IPNetworkCalculator/IPWorkspaceView.swift`: terminal header for IP modes.
- Modify `Sources/IPNetworkCalculator/BaseConversionView.swift`: terminal header, field styling, and bit-surface integration.
- Modify `Sources/IPNetworkCalculator/NetworkWorkspaceView.swift`: primary execution styling and HUD labels.
- Modify `Sources/IPNetworkCalculator/TranslationWorkspaceView.swift`: primary execution styling and HUD labels.
- Modify `Sources/IPNetworkCalculator/IPWorkspacePickerView.swift`: semantic cyan segmented-control tint.
- Modify `Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift`: semantic cyan segmented-control tint.
- Modify `Sources/IPNetworkCalculator/ResultPanelView.swift`: shared result-section surface and low-priority copy action chrome.
- Modify `Sources/IPNetworkCalculator/BinaryBitGridView.swift`: chamfered dark bit cells with semantic accents.
- Modify `Sources/IPNetworkCalculator/HistoryPopoverView.swift`: terminal header and low-priority action chrome.
- Modify `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`: theme isolation and structural regression tests.

### Task 1: Theme Model and Dark/Light Isolation

**Files:**
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`
- Modify: `Sources/IPNetworkCalculator/ThemeStyle.swift`

**Interfaces:**
- Produces: `ThemeVisualStyle`, `CalculatorTheme.visualStyle`, `accentSecondary`, `accentTertiary`, `gridOpacity`, `scanlineOpacity`, and `glowOpacity`.
- Consumers: all later visual components through `@Environment(\.calculatorTheme)`.

- [ ] **Step 1: Write failing theme tests**

Add tests that require the exact semantic split:

```swift
@Test
func darkThemeUsesNeonTacticalTokens() {
    let theme = CalculatorTheme.defaultDark

    #expect(theme.visualStyle == .neonTactical)
    #expect(theme.accentMode == .cyberGreen)
    #expect(theme.gridOpacity == 0.055)
    #expect(theme.scanlineOpacity == 0.16)
    #expect(theme.glowOpacity == 0.42)
}

@Test
func lightThemeRemainsClassicGlass() {
    let theme = CalculatorTheme.defaultLight

    #expect(theme.visualStyle == .classicGlass)
    #expect(theme.accentMode == .calculatorOrange)
    #expect(theme.gridOpacity == 0)
    #expect(theme.scanlineOpacity == 0)
    #expect(theme.glowOpacity == 0)
}
```

Update the old dark-orange and dark/light-equality expectations so they require Cyberpunk dark tokens but retain all existing light-theme values.

- [ ] **Step 2: Verify RED**

Run: `swift test --filter 'darkThemeUsesNeonTacticalTokens|lightThemeRemainsClassicGlass'`

Expected: compilation failure because the new enum cases and properties do not exist.

- [ ] **Step 3: Implement the theme model**

Add these exact public-to-target interfaces in `ThemeStyle.swift`:

```swift
enum ThemeVisualStyle: Equatable {
    case neonTactical
    case classicGlass
}

enum ThemeAccentMode: Equatable {
    case cyberGreen
    case calculatorOrange

    var tint: Color {
        switch self {
        case .cyberGreen: Color(red: 0, green: 1, blue: 0.533)
        case .calculatorOrange: Color(red: 1, green: 0.584, blue: 0)
        }
    }
}
```

Add the six produced properties to `CalculatorTheme`. Set dark to `neonTactical`, green `#00ff88`, cyan `#00d4ff`, magenta `#ff00ff`, grid `0.055`, scanline `0.16`, and glow `0.42`. Set light to `classicGlass`, keep orange, and use zero for the three effect opacities.

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter 'darkThemeUsesNeonTacticalTokens|lightThemeRemainsClassicGlass'`

Expected: both tests pass.

- [ ] **Step 5: Record checkpoint**

Run: `git diff --check -- Sources/IPNetworkCalculator/ThemeStyle.swift Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

Expected: no whitespace errors. Do not stage overlapping user changes.

### Task 2: Chamfered Geometry and Accessible Background

**Files:**
- Create: `Sources/IPNetworkCalculator/CyberpunkStyle.swift`
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

**Interfaces:**
- Consumes: `CalculatorTheme.visualStyle` and semantic neon tokens from Task 1.
- Produces: `ChamferedRectangle(cut:)`, `CalculatorWorkspaceBackground`, `CalculatorWorkspaceHeader(route:title:subtitle:)`, `calculatorPrimaryActionChrome()`, `calculatorSecondaryActionChrome()`, and `calculatorCyberButtonChrome(isActive:accent:)`.

- [ ] **Step 1: Write failing structural tests**

```swift
@Test
func cyberpunkPrimitivesProvideChamfersBackgroundAndReducedMotion() throws {
    let source = try sourceText(relativePath: "Sources/IPNetworkCalculator/CyberpunkStyle.swift")

    #expect(source.contains("struct ChamferedRectangle: InsettableShape"))
    #expect(source.contains("struct CalculatorWorkspaceBackground"))
    #expect(source.contains("@Environment(\\.accessibilityReduceMotion)"))
    #expect(source.contains(".allowsHitTesting(false)"))
}
```

- [ ] **Step 2: Verify RED**

Run: `swift test --filter cyberpunkPrimitivesProvideChamfersBackgroundAndReducedMotion`

Expected: FAIL because `CyberpunkStyle.swift` does not exist.

- [ ] **Step 3: Implement the primitives**

Implement `ChamferedRectangle` as an insettable path whose eight points are `(minX + cut, minY)`, `(maxX - cut, minY)`, `(maxX, minY + cut)`, `(maxX, maxY - cut)`, `(maxX - cut, maxY)`, `(minX + cut, maxY)`, `(minX, maxY - cut)`, and `(minX, minY + cut)`. Clamp the effective cut to half the inset rectangle's smaller dimension.

Build `CalculatorWorkspaceBackground` from a theme-colored base, two radial gradients, a `Canvas` grid at 44-point intervals, and a repeating horizontal scanline `Canvas`. Read `accessibilityReduceMotion`; only advance the bright scanline offset when motion is allowed. Apply `.allowsHitTesting(false)` and `.accessibilityHidden(true)` to the complete decorative layer.

Build `CalculatorWorkspaceHeader` as a `@ViewBuilder`: return an empty view for `.classicGlass`; otherwise render route, title, subtitle, and a small blinking green cursor using system monospaced fonts. Keep RGB splitting static through layered text shadows/offset duplicates and hide duplicates from accessibility.

Implement the three button modifiers so classic light delegates to current system button styles and Neon Tactical uses chamfered backgrounds, semantic borders, dark-on-green primary text, and restrained glow.

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter cyberpunkPrimitivesProvideChamfersBackgroundAndReducedMotion`

Expected: PASS.

Run: `swift build`

Expected: `Build complete!` with exit code 0.

- [ ] **Step 5: Record checkpoint**

Run: `git diff --check -- Sources/IPNetworkCalculator/CyberpunkStyle.swift Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

Expected: no whitespace errors.

### Task 3: Style-Aware Shared Surfaces

**Files:**
- Modify: `Sources/IPNetworkCalculator/GlassStyle.swift`
- Modify: `Sources/IPNetworkCalculator/ResultPanelView.swift`
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

**Interfaces:**
- Consumes: `ChamferedRectangle` and `ThemeVisualStyle`.
- Produces: unchanged public view APIs `calculatorWorkspaceSurface()`, `calculatorFormSurface()`, `calculatorPopoverSurface()`, and `calculatorFieldChrome(invalid:)`, plus `calculatorResultSectionSurface()`.

- [ ] **Step 1: Write failing integration tests**

```swift
@Test
func sharedSurfaceModifiersRouteThroughCyberpunkGeometry() throws {
    let glass = try sourceText(relativePath: "Sources/IPNetworkCalculator/GlassStyle.swift")
    let results = try sourceText(relativePath: "Sources/IPNetworkCalculator/ResultPanelView.swift")

    #expect(glass.contains("theme.visualStyle == .neonTactical"))
    #expect(glass.contains("ChamferedRectangle"))
    #expect(glass.contains("calculatorResultSectionSurface"))
    #expect(results.contains(".calculatorResultSectionSurface()"))
}
```

- [ ] **Step 2: Verify RED**

Run: `swift test --filter sharedSurfaceModifiersRouteThroughCyberpunkGeometry`

Expected: FAIL because the modifiers do not route through Cyberpunk geometry.

- [ ] **Step 3: Implement style-aware surfaces**

In each modifier, branch once on `theme.visualStyle`. The Neon Tactical branch uses `ChamferedRectangle(cut: 10)` for fields, `14` for result sections, `16` for form/workspace surfaces, and `14` for popovers. It uses `theme.chromeElevated` or `theme.contentBase`, a semantic accent border, a two-point illuminated top-leading marker, and glow opacity from the theme. The classic branch must preserve the existing `RoundedRectangle` code verbatim.

Move the result-section background and border into `calculatorResultSectionSurface()` and replace only that duplicated block in `ResultSectionContainer`.

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter sharedSurfaceModifiersRouteThroughCyberpunkGeometry`

Expected: PASS.

Run: `swift build`

Expected: exit code 0.

- [ ] **Step 5: Record checkpoint**

Run: `git diff --check -- Sources/IPNetworkCalculator/GlassStyle.swift Sources/IPNetworkCalculator/ResultPanelView.swift`

Expected: no whitespace errors.

### Task 4: App Chrome, Sidebar, and Workspace Headers

**Files:**
- Modify: `Sources/IPNetworkCalculator/ContentView.swift`
- Modify: `Sources/IPNetworkCalculator/SidebarNavigationView.swift`
- Modify: `Sources/IPNetworkCalculator/IPWorkspaceView.swift`
- Modify: `Sources/IPNetworkCalculator/BaseConversionView.swift`
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

**Interfaces:**
- Consumes: `CalculatorWorkspaceBackground`, `CalculatorWorkspaceHeader`, and the existing navigation bindings.
- Produces: no new model interface; only presentation composition.

- [ ] **Step 1: Write failing composition tests**

```swift
@Test
func rootAndWorkspacesComposeNeonTacticalPresentation() throws {
    let content = try sourceText(relativePath: "Sources/IPNetworkCalculator/ContentView.swift")
    let sidebar = try sourceText(relativePath: "Sources/IPNetworkCalculator/SidebarNavigationView.swift")
    let ip = try sourceText(relativePath: "Sources/IPNetworkCalculator/IPWorkspaceView.swift")
    let base = try sourceText(relativePath: "Sources/IPNetworkCalculator/BaseConversionView.swift")

    #expect(content.contains("CalculatorWorkspaceBackground"))
    #expect(sidebar.contains("theme.visualStyle == .neonTactical"))
    #expect(ip.contains("CalculatorWorkspaceHeader"))
    #expect(base.contains("CalculatorWorkspaceHeader"))
}
```

- [ ] **Step 2: Verify RED**

Run: `swift test --filter rootAndWorkspacesComposeNeonTacticalPresentation`

Expected: FAIL on all four missing composition points.

- [ ] **Step 3: Implement composition**

Place `CalculatorWorkspaceBackground()` behind the detail `VStack` in `ContentView` and retain the current `toolbar` block exactly. In `SidebarNavigationView`, keep the current full-width `Button` hit target and branch only its foreground, fill, border, shape, and glow. Add a small, accessibility-hidden local telemetry block at the bottom only for Neon Tactical.

Insert these headers before existing controls:

```swift
CalculatorWorkspaceHeader(
    route: "WORKSPACE / IP_CALCULATOR",
    title: "NETWORK TERMINAL",
    subtitle: "解析 IPv4 / IPv6 地址、子网与映射关系"
)
```

```swift
CalculatorWorkspaceHeader(
    route: "WORKSPACE / BASE_CONVERSION",
    title: "BASE TRANSCODER",
    subtitle: "同步转换 2 / 10 / 16 进制数值"
)
```

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter rootAndWorkspacesComposeNeonTacticalPresentation`

Expected: PASS.

Run: `swift build`

Expected: exit code 0.

- [ ] **Step 5: Record checkpoint**

Run: `git diff --check -- Sources/IPNetworkCalculator/ContentView.swift Sources/IPNetworkCalculator/SidebarNavigationView.swift Sources/IPNetworkCalculator/IPWorkspaceView.swift Sources/IPNetworkCalculator/BaseConversionView.swift`

Expected: no whitespace errors and no toolbar regression.

### Task 5: Calculator Controls, Results, History, and Bit Grid

**Files:**
- Modify: `Sources/IPNetworkCalculator/NetworkWorkspaceView.swift`
- Modify: `Sources/IPNetworkCalculator/TranslationWorkspaceView.swift`
- Modify: `Sources/IPNetworkCalculator/IPWorkspacePickerView.swift`
- Modify: `Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift`
- Modify: `Sources/IPNetworkCalculator/ResultPanelView.swift`
- Modify: `Sources/IPNetworkCalculator/BinaryBitGridView.swift`
- Modify: `Sources/IPNetworkCalculator/HistoryPopoverView.swift`
- Modify: `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

**Interfaces:**
- Consumes: shared Cyberpunk button and surface modifiers.
- Produces: unchanged callbacks, bindings, copy actions, and bit-toggle indices.

- [ ] **Step 1: Write failing control tests**

```swift
@Test
func calculatorControlsUseSemanticCyberpunkChrome() throws {
    let network = try sourceText(relativePath: "Sources/IPNetworkCalculator/NetworkWorkspaceView.swift")
    let translation = try sourceText(relativePath: "Sources/IPNetworkCalculator/TranslationWorkspaceView.swift")
    let bits = try sourceText(relativePath: "Sources/IPNetworkCalculator/BinaryBitGridView.swift")
    let history = try sourceText(relativePath: "Sources/IPNetworkCalculator/HistoryPopoverView.swift")

    #expect(network.contains(".calculatorPrimaryActionChrome()"))
    #expect(translation.contains(".calculatorPrimaryActionChrome()"))
    #expect(bits.contains("ChamferedRectangle"))
    #expect(history.contains(".calculatorSecondaryActionChrome()"))
}
```

- [ ] **Step 2: Verify RED**

Run: `swift test --filter calculatorControlsUseSemanticCyberpunkChrome`

Expected: FAIL because the shared control chrome is not connected.

- [ ] **Step 3: Implement control integration**

Replace only `.buttonStyle(.borderedProminent)` on calculate buttons with `.calculatorPrimaryActionChrome()`. Tint both segmented pickers with `theme.visualStyle == .neonTactical ? theme.accentSecondary : theme.accentMode.tint`. Apply secondary action chrome to copy/restore buttons while keeping their labels, callbacks, disabled state, context menus, and control sizes.

In `BinaryBitGridView`, use `ChamferedRectangle(cut: 4)` only for Neon Tactical bit cells. Keep the existing rounded rectangle path for classic light. Map `1` to primary green, `0` to the current elevated neutral, and group markers/dividers to cyan/semantic divider tokens. Do not alter `bitIndex`, row grouping, or fixed-size behavior.

Prefix dark field labels and result section titles with compact numbered HUD text through accessibility-hidden decoration; retain the original Chinese labels as the accessible content.

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter calculatorControlsUseSemanticCyberpunkChrome`

Expected: PASS.

Run: `swift test --filter 'BinaryBitGrid|NormalizingTextField'`

Expected: all layout, toggle-index, normalization, punctuation, and Return-key tests pass.

- [ ] **Step 5: Record checkpoint**

Run: `git diff --check -- Sources/IPNetworkCalculator Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

Expected: no whitespace errors.

### Task 6: Full Regression and Visual Verification

**Files:**
- Verify all modified files.
- Update tests only if a failure reveals a real missing requirement; do not weaken assertions to make failures disappear.

**Interfaces:**
- Consumes: complete Neon Tactical presentation.
- Produces: verified package and final dark-theme screenshot.

- [ ] **Step 1: Run the full test suite**

Run: `swift test`

Expected: every test passes with zero failures.

- [ ] **Step 2: Run a release build**

Run: `swift build -c release`

Expected: `Build complete!` and exit code 0.

- [ ] **Step 3: Inspect the complete diff**

Run: `git diff --check`

Expected: no whitespace errors.

Run: `git diff --stat` and `git status --short`

Expected: only the known pre-existing files, the planned Cyberpunk source/test changes, and the implementation plan are present; no build products are tracked.

- [ ] **Step 4: Launch and verify both appearances**

Run the executable, inspect dark and light appearances at the 980×640 minimum and at a larger window, and verify:

- Neon Tactical dark background, chamfered surfaces, glow, scanlines, terminal headers, sidebar, fields, result sections, history, and bit cells render correctly.
- Light mode keeps the existing classic glass styling.
- Return calculates, copying works, history restores, invalid input shows text plus border, bit cells toggle the intended index, and toolbar controls remain separate system buttons.
- With Reduce Motion enabled, blinking and moving scanlines stop while static texture remains.

- [ ] **Step 5: Capture final evidence**

Capture a dark-theme screenshot in the workspace temporary evidence directory and compare it with the approved A mockup. Record any deliberate platform-native differences in the handoff.

- [ ] **Step 6: Final verification rerun**

Run: `swift test && swift build -c release && git diff --check`

Expected: exit code 0 for all commands immediately before completion is claimed.

# Cyberpunk Dark Theme Design

## Summary

Restyle only the calculator's dark appearance as a balanced Cyberpunk “Neon Tactical” interface. Preserve the current light appearance, information architecture, calculator behavior, history behavior, and toolbar behavior.

The approved direction uses electric green as the primary interaction color, cyan as a secondary information color, and magenta only for restrained chromatic-aberration accents. Dark surfaces become angular terminal panels with subtle grid, scanline, glow, and signal-status details. Readability and calculator efficiency remain more important than decorative intensity.

## Goals

- Make the dark appearance unmistakably Cyberpunk without obscuring calculator content.
- Centralize visual decisions in the existing theme and view-modifier layers.
- Reuse a small set of shapes and modifiers across navigation, forms, results, history, and bit controls.
- Preserve keyboard, copy, history, validation, and calculation workflows.
- Respect macOS accessibility settings and maintain clear focus and error states.
- Leave all light-theme visual tokens and classic glass presentation unchanged.

## Non-Goals

- No calculation, normalization, conversion, history, or persistence changes.
- No navigation restructuring or new calculator feature.
- No external font or image dependency.
- No replacement of the current system toolbar controls.
- No aggressive continuous glitching, large particle system, audio, or high-cost visual effect.

## Approved Visual Direction

The selected direction is **A — Neon Tactical**.

- Base background: near-black with a slight green-blue undertone.
- Primary accent: electric green for selection, execution, focus, and active bits.
- Secondary accent: cyan for informational state, selected sub-tabs, and secondary output emphasis.
- Tertiary accent: magenta used sparingly in static RGB text splitting and tiny signal artifacts.
- Typography: system monospaced faces for labels, values, fields, and terminal metadata; system sans serif may remain for ordinary explanatory copy where it improves Chinese readability.
- Shapes: 45-degree chamfered panels and controls replace rounded dark-theme cards.
- Texture: low-opacity circuit grid on the workspace and a non-interactive scanline overlay across the dark content region.
- Light: colored borders use restrained stacked glow, strongest on active controls and keyboard focus.
- Motion: short mechanical transitions, a blinking terminal cursor, and infrequent title glitch movement. Motion is removed when Reduce Motion is enabled.

## Theme Architecture

Add a theme-level visual-style discriminator with two values:

- `neonTactical` for `CalculatorTheme.defaultDark`
- `classicGlass` for `CalculatorTheme.defaultLight`

Extend the theme with named Cyberpunk-compatible tokens instead of embedding color literals throughout views. The token set covers primary, secondary, and tertiary accents; panel and field borders; grid and scanline opacity; glow color and intensity; error color; and motion eligibility.

Existing surface structs remain the source of spacing, opacity, and stroke values. They gain only the shape/effect information necessary to render either a chamfered Neon Tactical surface or the existing rounded classic surface. Light-theme token values and classic geometry remain identical to their current values.

Views consume the theme through `EnvironmentValues.calculatorTheme`, as they do now. They do not inspect the system color scheme directly and do not duplicate `if dark` checks.

## Reusable Visual Components

### Chamfered Shape

Introduce one reusable `InsettableShape` that draws a rectangle with configurable 45-degree corner cuts. Use a smaller cut for fields, buttons, navigation rows, and bit cells and a larger cut for panels and popovers. The classic light visual style continues to render continuous rounded rectangles.

### Background Layer

The dark content area receives a reusable background composition:

1. near-black base color;
2. faint cyan and green radial illumination near opposite edges;
3. low-opacity grid or circuit lines;
4. a full-area scanline overlay that ignores hit testing.

The overlay must not change layout, intercept pointer events, or reduce text contrast below readable levels.

### Surface Modifiers

Refactor the existing workspace, form, field, and popover modifiers so each chooses geometry and effects from the theme visual style:

- Neon Tactical surfaces use chamfered shapes, technical one-pixel borders, a short illuminated edge marker, and restrained accent glow.
- Classic light surfaces retain their existing rounded shape, highlight, opacity, and shadow behavior.

Result-section containers use the same surface primitive instead of maintaining a separate one-off rounded implementation.

### Terminal Header and HUD Labels

Dark workspaces receive a compact terminal header above their existing controls. It contains an uppercase monospaced workspace title, a small route/status line, and a restrained static RGB split on the main title. IP calculation and base conversion get meaningful titles based on the selected workspace.

Small reusable HUD labels add prefixes such as `>` and numbered section identifiers where helpful. These labels are decorative or redundant with visible Chinese labels, so VoiceOver does not announce meaningless punctuation.

### Controls

- Active sidebar rows use a green fill, dark high-contrast text, chamfered geometry, and a small glow.
- IP mode and translation direction pickers use cyan for their active state so they remain distinct from the primary execution action.
- Primary calculate actions use solid electric green with dark text and preserve the Return keyboard shortcut.
- Inputs use a dark inset surface, a green leading edge/prompt, monospaced value text, and a clear focus ring.
- Invalid inputs use the existing error semantics with a brighter red-pink border and accompanying text.
- Bit cells use green for `1`, subdued neutral styling for `0`, and cyan group markers; all existing click targets and bit-index behavior remain unchanged.
- Copy and restore controls use lower-intensity outline styling so they do not compete with calculate actions.

## Screen-Level Behavior

### App Chrome and Sidebar

The current integrated sidebar width and navigation structure remain unchanged. Only the dark background, divider, labels, selection styling, and optional non-interactive telemetry decoration change. The current system toolbar theme toggle and history buttons remain system controls.

### IP Calculation and Translation

The existing picker, form fields, calculate button, validation, and result panel retain their order and data bindings. The form becomes terminal section `01`; result output becomes section `02`. Translation keeps its two-column field layout where space allows and uses the same field primitive.

### Base Conversion

The three synchronized base fields retain their bindings and horizontal desktop layout. The 32-bit grid receives the Neon Tactical cell treatment without changing its intrinsic compact sizing, two-row grouping, markers, or toggle semantics.

### History Popover

History retains its current width, scrolling behavior, copy/restore actions, and empty state. In dark mode the popover uses a chamfered terminal surface and low-intensity outlined entry separators. In light mode it remains the current glass popover.

## Data Flow and State

The feature and core targets are unchanged. Views continue to bind directly to the existing observable view models:

- `CalculatorWorkbenchViewModel` owns navigation, workspaces, history, and restoration.
- Workspace view models continue to normalize and calculate from input changes.
- `ResultPanelView` continues to receive immutable result sections and copy strings.
- `ClipboardService` continues to handle copy actions.
- `CalculatorAppearance` continues to select the persisted dark or light appearance and supplies the corresponding theme.

New visual state is local and presentation-only: short copy feedback, optional cursor phase, and accessibility-driven animation enablement. No visual state is written into calculator models or persisted alongside calculation data.

## Error Handling

- Existing validation messages and error strings remain authoritative.
- Invalid fields gain a visible error border in addition to existing error text.
- Error text keeps sufficient contrast and is not represented by color alone.
- Decorative animation failure cannot block input, calculation, copying, or navigation because decoration has no dependency in the data path.
- Background and scanline overlays disable hit testing.

## Accessibility and Responsiveness

- Honor `accessibilityReduceMotion`; disable blinking, glitch translation, and animated scanline movement while keeping static texture.
- Retain keyboard focus, Return-to-calculate, and existing button accessibility labels.
- Ensure dark text on solid green active controls and light text on dark surfaces meet WCAG AA contrast targets.
- Keep decorative terminal metadata hidden from accessibility when it duplicates visible meaning.
- Preserve minimum practical macOS pointer targets and avoid shrinking current control frames.
- Allow narrow windows to wrap or vertically stack headers and multi-field form rows before truncating input content.
- Prefer system monospaced fonts to avoid network loading and to maintain reliable Chinese fallback.

## Testing and Verification

Use test-first development for the theme behavior and structural integration:

1. Add failing tests proving dark uses Neon Tactical tokens and geometry while light remains classic and retains its current values.
2. Add failing structural tests for the reusable chamfered shape, background overlay, workspace header, and Reduce Motion handling.
3. Implement the smallest theme and view changes needed to pass each test.
4. Run all Swift package tests.
5. Build the executable in release configuration.
6. Launch the macOS application and inspect both appearances at representative window sizes.
7. Verify calculation, Return submission, copying, history restoration, bit toggling, invalid input, appearance switching, keyboard focus, and Reduce Motion behavior.
8. Capture a final dark-theme screenshot for visual comparison with the approved Neon Tactical mockup.

## Expected File Scope

Primary implementation work is expected in:

- `Sources/IPNetworkCalculator/ThemeStyle.swift`
- `Sources/IPNetworkCalculator/GlassStyle.swift`
- `Sources/IPNetworkCalculator/ContentView.swift`
- `Sources/IPNetworkCalculator/SidebarNavigationView.swift`
- workspace, result, history, picker, and bit-grid SwiftUI views as required for shared styling
- `Tests/IPNetworkCalculatorTests/DarkThemeStyleTests.swift`

A focused new source file may hold the chamfered shape and terminal decoration views if keeping them in `GlassStyle.swift` would make that file difficult to navigate.

## Success Criteria

- Dark mode matches the approved Neon Tactical direction at first glance.
- Light mode retains its existing classic appearance.
- Calculator workflows and outputs are unchanged.
- Cyberpunk styling is centralized and reused rather than copied between views.
- Animations are subtle, optional, and disabled by Reduce Motion.
- All tests pass, release build succeeds, and manual visual/interaction verification finds no blocking issue.

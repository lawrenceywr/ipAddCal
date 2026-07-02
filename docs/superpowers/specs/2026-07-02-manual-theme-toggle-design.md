# Manual Theme Toggle Design

Date: 2026-07-02

## Context

The app now has a fixed dark, system-calculator-inspired appearance with an orange accent direction and recent chrome fixes:

- the sidebar should read as structural window chrome, not a floating card
- the history toolbar button should have one relaxed border, not a stacked double border
- sidebar navigation rows should be clickable across their full visual row, not only on the text
- title text and page headings should not carry decorative emphasis borders

The new request is to add a first-class light mode and a manual dark/light switch. This must build on the current dark/orange work without reintroducing the earlier chrome problems.

## Confirmed Decisions

- Add only a manual dark/light toggle.
- Do not add a follow-system option in this pass.
- Persist the user's selected appearance across launches.
- Default existing and new installs to the current dark appearance so users do not get a sudden bright UI after upgrade.
- Keep the calculator-style orange accent in both modes.
- Place the theme toggle in the top-right toolbar immediately beside the existing history button.
- Use a separate icon-only button for the theme toggle. It must not be centered in the title bar, merged into the history button, or placed in the sidebar.

## Goals

- Let users switch between deep dark mode and a readable light mode without changing calculator behavior.
- Keep both modes visually related: black/orange in dark mode, light neutral/orange in light mode.
- Move views away from hard-coded `CalculatorTheme.defaultDark` usage so appearance can be selected at runtime.
- Preserve the integrated sidebar and toolbar treatment from the latest polish.
- Make the toggle discoverable and accessible while keeping the title bar calm.

## Non-Goals

- No automatic system appearance following.
- No user-configurable accent colors.
- No changes to IP calculation, IPv4/IPv6 translation, base conversion, history semantics, copy behavior, or validation rules.
- No redesign of navigation or workspace layout.
- No movement of UI styling state into `IPCalculatorCore` or `IPCalculatorFeatures`.
- No changes to unrelated packaging files currently untracked in the worktree.

## Visual Design

### Theme Toggle Placement

The title area keeps the current structure:

- window controls and sidebar toggle remain on the left
- title remains in the normal title/titlebar area
- right-side toolbar controls contain the new theme toggle followed by the existing `历史` button

The theme toggle should sit immediately to the left of `历史`, with the same vertical alignment and compatible button hit area. It should be close enough to read as part of the same toolbar control cluster, but visually independent.

The toggle is icon-only:

- dark mode shows a sun-style icon because the next action is switching to light mode
- light mode shows a moon-style icon because the next action is switching to dark mode
- provide help text and an accessibility label, for example "Switch to Light Mode" and "Switch to Dark Mode"

### Dark Mode

Dark mode remains the default and should preserve the current approved direction:

- deep graphite or near-black window base
- integrated sidebar and toolbar chrome
- orange primary accent close to system Calculator orange
- no decorative title-border treatment
- relaxed single-border history button
- full-row sidebar hit targets

### Light Mode

Light mode should be a real palette, not an inverted dark theme. It should feel like the same utility app under a light neutral surface system:

- window base: soft neutral light gray, not pure white
- sidebar and toolbar: slightly stronger neutral chrome so the app frame remains structural
- workspace panels: clean light surfaces with subtle borders and restrained shadows
- text fields: clear input boundaries without heavy dark outlines
- result sections: visible grouping without card-on-card clutter
- accent: same orange family for primary actions, selected sidebar item, active segmented controls, and focus emphasis

The light mode should avoid large blue/purple gradients, beige-heavy palettes, and decorative background shapes. It should stay closer to a practical macOS utility than a marketing page.

## Architecture

### Appearance State

Introduce an app-target appearance model, for example:

- `CalculatorAppearance`: `.dark` and `.light`
- raw-value persistence through `@AppStorage("calculatorAppearance")`
- a default and invalid-value fallback of `.dark`
- a computed `colorScheme` mapping to `.dark` or `.light`
- a computed `theme` mapping to `CalculatorTheme.defaultDark` or `CalculatorTheme.defaultLight`

This state belongs in `IPNetworkCalculator`, not in the core or feature packages.

### Theme Tokens

Extend the existing theme layer rather than adding one-off color literals in views.

`CalculatorTheme` should have explicit dark and light defaults:

- `CalculatorTheme.defaultDark`
- `CalculatorTheme.defaultLight`

Both themes should define the same semantic surface and control tokens:

- accent/tint
- window base
- chrome base and elevated chrome
- content base
- divider
- primary and secondary text treatment where needed
- error color
- field chrome
- form/workspace surface
- result section surface
- popover surface
- sidebar and toolbar chrome metrics
- history button chrome metrics

Runtime views should consume the selected theme through a single mechanism, such as a custom environment value or explicit root injection. The implementation should remove hard-coded `CalculatorTheme.defaultDark` references from views and modifiers, except in tests, fixtures, and the static theme definitions themselves.

### Root Wiring

`IPNetworkCalculatorApp` should own the persisted appearance choice and apply:

- `.preferredColorScheme(selectedAppearance.colorScheme)`
- `.tint(selectedAppearance.theme.accentMode.tint)`
- the selected theme through the chosen injection mechanism

`ContentView` should receive or read the active theme and use it for:

- root background
- toolbar/chrome colors
- sidebar chrome
- right-side toolbar control cluster
- history popover
- workspace surfaces

### Component Coverage

The selected theme must reach every visible app area:

- `ContentView`
- `SidebarNavigationView`
- `GlassStyle`
- `IPWorkspacePickerView`
- `TranslationDirectionPickerView`
- `NetworkWorkspaceView`
- `TranslationWorkspaceView`
- `BaseConversionView`
- `BinaryBitGridView`
- `ResultPanelView`
- `HistoryPopoverView`

The implementation can add small helper views or modifiers for toolbar icon buttons, but the toggle should not introduce a new navigation model or change feature state.

## Behavior

- On first launch or invalid stored value, the app starts in dark mode.
- Clicking the theme toggle switches the selected appearance immediately.
- The choice persists and is restored on the next launch.
- The history popover remains controlled only by the history button.
- Changing theme must not clear inputs, reset selected workspace, alter history, or recompute results.

## Accessibility

- The icon-only toggle must have an accessibility label and help text.
- The hit area should match normal toolbar controls and remain easy to click.
- Icon contrast must pass visually in both light and dark modes.
- Orange active controls must remain readable against both dark and light surfaces.
- The sidebar row hit target fix must remain intact for both navigation rows.

## Testing

Add focused tests that make the behavior and styling decisions hard to regress:

- `CalculatorAppearance` defaults to dark.
- Invalid persisted raw values fall back to dark.
- `.dark` maps to `CalculatorTheme.defaultDark` and `.light` maps to `CalculatorTheme.defaultLight`.
- `CalculatorTheme.defaultLight` defines the same required semantic tokens as `defaultDark`.
- The orange accent is shared across both themes.
- Source/style tests confirm app views no longer hard-code `CalculatorTheme.defaultDark` outside allowed definitions and tests.

Run the existing Swift test suite after implementation. Also run the app locally and visually smoke both modes, checking the toolbar button cluster, sidebar integration, history popover, IP workspace, IPv4/IPv6 translation workspace, and base conversion workspace.

## Risks and Mitigations

- **Risk:** light mode becomes a shallow color inversion and looks unfinished.
  **Mitigation:** define explicit light tokens for chrome, surfaces, fields, result sections, and popovers before touching view styling.

- **Risk:** runtime theme injection leaves scattered hard-coded dark references.
  **Mitigation:** add a source-level regression test or targeted `rg` check as part of implementation.

- **Risk:** the new toolbar control revives the double-border history issue.
  **Mitigation:** keep the theme toggle as its own icon button and keep history button chrome applied only to the history label/control, not to nested toolbar containers.

- **Risk:** appearance switching resets working state.
  **Mitigation:** keep appearance state separate from `CalculatorWorkbenchViewModel` and do not recreate the workbench as part of the toggle.

## Acceptance Criteria

- The app launches in dark mode by default.
- A theme toggle appears immediately to the left of `历史` in the right-side toolbar cluster.
- Clicking the toggle switches between dark and light modes and persists the selection.
- Both modes keep the orange calculator accent.
- The sidebar remains integrated with the window chrome and does not look like a floating card.
- Title and page heading text have no decorative border treatment.
- The history button has one relaxed border, not two stacked borders.
- Sidebar navigation rows are clickable across their full visual row.
- All existing tests pass, and new appearance/theme tests pass.

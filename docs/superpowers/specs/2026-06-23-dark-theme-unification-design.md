# Dark Theme Unification Design

Date: 2026-06-23

## Context

The macOS-native migration is functionally complete. The current app already has:

- a SwiftUI app shell in `IPNetworkCalculator`
- feature-oriented state in `IPCalculatorFeatures`
- pure calculation logic in `IPCalculatorCore`
- a native workbench layout with sidebar navigation, toolbar history, and dedicated workspaces

The remaining problem is visual consistency. The current UI still mixes:

- light-material workspace surfaces
- default system control styling
- partially tuned spacing and panel hierarchy
- localized glass treatments that do not yet form one coherent dark visual system

The user wants the next pass to focus on visual unification first, and specifically wants a deep macOS-style dark appearance inspired by the system Calculator rather than the current light workspace look.

## Confirmed Decisions

- Deliver a single fixed dark theme for the current version.
- Do not add a light/dark toggle.
- Do not follow the system appearance dynamically.
- Keep macOS blue as the primary accent color.
- Increase Liquid Glass presence relative to the current version.
- Keep input, result, and history boundaries clearly separated rather than visually blending them together.
- Apply the dark treatment across the whole app at once:
  - sidebar
  - toolbar/title area
  - IP calculation workspace
  - base conversion workspace
  - history popover

## Goals

- Make the whole app read as one intentional macOS dark utility instead of a light prototype with isolated glass panels.
- Preserve all current workflows and behaviors while replacing the visual hierarchy.
- Keep the app close to the feel of system utility apps: dark graphite base, restrained color usage, strong readability, and crisp container boundaries.
- Reuse centralized style tokens so later polish does not require page-by-page restyling again.

## Non-Goals

- Do not change calculation behavior, state flow, or result semantics.
- Do not add theme settings, persistence, or system-following appearance behavior.
- Do not redesign navigation structure, window layout, or workspace responsibilities.
- Do not move UI styling concerns into `IPCalculatorCore` or `IPCalculatorFeatures`.
- Do not chase an exaggerated showcase-style glass aesthetic that reduces text clarity.

## Chosen Visual Direction

Three directions were considered:

1. system-calculator-style deep dark
2. stronger liquid-glass-forward dark UI
3. flatter professional tool dark UI

The selected direction is **system-calculator-style deep dark**, with one deliberate adjustment: preserve a more visible glass/highlight treatment than the current app, but keep that effect at the container level rather than the row level.

This yields the following visual rules:

- base tone is deep graphite gray, not pure black
- surfaces separate by subtle contrast steps, not hard black/white jumps
- the accent color stays blue and is reserved for focus, selection, and primary actions
- glass shows up as blur, cool edge highlight, and soft reflective lift on major containers
- row content and dense text remain readability-first

## Visual System

### 1. Global Appearance

The app should run in a fixed dark appearance so the window, sidebar, toolbar, and content surfaces all share one consistent environment.

This should be enforced at the app/root view level, with `.preferredColorScheme(.dark)` as the default path. A small AppKit bridge is acceptable only if SwiftUI alone cannot keep sidebar or toolbar chrome in the same dark appearance. The goal is a coherent platform appearance first, with custom styling layered on top.

### 2. Background Hierarchy

The dark hierarchy should have three main levels:

- **Window background:** deepest graphite base
- **Chrome surfaces:** sidebar and toolbar, slightly lifted from the window background
- **Workspace surfaces:** input panels, result panels, base conversion panels, and history popover, each brighter than chrome but still clearly dark

This hierarchy should make the main working panels legible immediately without requiring thick borders or bright fills.

### 3. Accent Strategy

Accent usage is intentionally narrow:

- selected sidebar item
- focused or selected segmented controls
- prominent calculate buttons
- active/focused control states
- optional subtle feedback emphasis where blue improves scannability

Blue should not be sprayed across labels, section titles, or passive text. Most of the UI should remain neutral grayscale.

### 4. Glass and Highlight Strategy

The user selected a stronger glass presence than the current build. That does not mean every control gets glow.

Glass should be stronger in:

- workspace surfaces
- popovers
- toolbar/sidebar chrome transitions

Glass should stay minimal in:

- result rows
- dense numeric values
- binary bit buttons
- inline helper text

The intended effect is:

- visible blur/material depth
- cool light edge highlight
- faint reflective lift on container tops
- reduced reliance on opaque white strokes

## Surface and Control Design

### 1. Workspace Surfaces

`calculatorWorkspaceSurface()` should become the main container primitive for the dark UI.

Responsibilities:

- apply a dark material/tint stack
- provide a unified rounded shape
- apply subtle border/highlight treatment
- create enough contrast to separate panels from the background

The same principle should apply to `calculatorPopoverSurface()`, but transient surfaces may use slightly brighter contrast to preserve legibility in smaller areas.

### 2. Sidebar

The sidebar should become the darkest persistent region in the app, close to the system Calculator or native utility sidebars:

- dark graphite background
- minimal internal ornament
- macOS-blue selected state
- low-noise list presentation

The sidebar should feel structural, not decorative.

### 3. Toolbar and Title Area

The toolbar should stay native in structure but visually harmonize with the dark palette:

- dark background matching chrome hierarchy
- restrained separator behavior
- no bright white title area

The title should remain legible and centered, but it should not compete with the workspace panels.

### 4. Text Fields and Buttons

The current app relies on default control styling in several places. That is acceptable functionally, but it weakens visual consistency.

Controls should be tuned so that:

- text fields sit correctly inside the dark hierarchy
- segmented controls feel intentional in dark mode
- standard buttons read as neutral controls
- prominent buttons preserve blue emphasis
- error states stay red, but with lower glare than bright default red on light surfaces

This work should remain SwiftUI-first. Only bridge to AppKit if a specific control appearance gap blocks a coherent result.

### 5. Result Sections

`ResultPanelView` currently uses `GroupBox`, which tends to pull in system-default visual assumptions. The result panel should instead use app-owned section chrome so that section grouping stays visually consistent with the dark theme.

The result structure itself should remain unchanged:

- same sections
- same rows
- same copy behaviors
- same empty/error handling

Only the container styling and row-level presentation should change.

### 6. Base Conversion Binary Grid

The binary grid already has improved spacing and compaction. In this theme pass it should be visually integrated, not restructured.

Requirements:

- keep the current grouped layout
- preserve click-to-toggle behavior
- avoid glowing or over-highlighting every bit cell
- ensure the panel still feels like a tool surface, not a decorative card

## Implementation Boundaries

The implementation should stay inside `IPNetworkCalculator`. Theme tokens and surface modifiers should live in the existing style layer there, such as `GlassStyle.swift` or a small adjacent style file in the same target.

Expected touch points:

- `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`
- `Sources/IPNetworkCalculator/ContentView.swift`
- `Sources/IPNetworkCalculator/GlassStyle.swift`
- `Sources/IPNetworkCalculator/SidebarNavigationView.swift`
- `Sources/IPNetworkCalculator/HistoryPopoverView.swift`
- `Sources/IPNetworkCalculator/ResultPanelView.swift`
- `Sources/IPNetworkCalculator/IPWorkspaceView.swift`
- `Sources/IPNetworkCalculator/NetworkWorkspaceView.swift`
- `Sources/IPNetworkCalculator/TranslationWorkspaceView.swift`
- `Sources/IPNetworkCalculator/BaseConversionView.swift`
- `Sources/IPNetworkCalculator/BinaryBitGridView.swift`
- picker/helper views whose controls need theme alignment

The implementation should avoid pushing appearance state into:

- `IPCalculatorCore`
- `IPCalculatorFeatures`
- result mapping logic
- history generation logic
- clipboard behavior

## Architecture Guidance

This pass is mostly visual, but it should still improve style architecture rather than scatter color literals.

The chosen structure is:

- add centralized dark theme tokens near the existing workspace style layer
- keep view code consuming semantic colors/surfaces instead of raw RGBA values where practical
- reuse one surface system across both workspaces and the popover
- localize one-off adjustments only where a component genuinely has unique needs

This keeps future polish incremental instead of forcing another styling sweep.

## Risks and Mitigations

### Risk 1: Too much glass makes dense information harder to read

Mitigation:

- keep stronger glass at panel boundaries, not rows
- preserve neutral text contrast
- avoid bright reflections behind numeric content

### Risk 2: SwiftUI default controls may still leak light-theme assumptions

Mitigation:

- first try tint/material/background-based styling
- if a specific control remains visually out of place, wrap the adjustment in a small dedicated modifier
- use AppKit only if SwiftUI styling cannot reach an acceptable result

### Risk 3: Theme work accidentally becomes layout redesign

Mitigation:

- keep layout changes minimal and directly tied to visual hierarchy
- do not revisit navigation structure or interaction rules during this pass

## Testing and Validation

Verification should be lightweight but explicit:

1. run `swift test`
2. run `swift run IPNetworkCalculator`
3. visually inspect:
   - sidebar selected state
   - toolbar/title contrast
   - input panel readability
   - result panel section clarity
   - base conversion dark styling
   - history popover contrast and button readability

Success means:

- no behavior regressions
- no illegible text or low-contrast controls
- one consistent dark hierarchy across all major surfaces
- a visibly stronger, but still disciplined, glass treatment

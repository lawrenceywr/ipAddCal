# macOS Native Workbench UI Design

Date: 2026-06-17

## Context

The repository has already completed the Tauri-to-Swift migration. The current app is a working Swift package with three layers:

- `IPCalculatorCore`: pure calculation, parsing, normalization, and formatting.
- `IPCalculatorFeatures`: view-model state, history, result rows, and base conversion state.
- `IPNetworkCalculator`: SwiftUI app shell and current desktop UI.

The current functionality is complete, but the UI still reflects a migration-stage structure:

- `ContentView` uses a simple `NavigationSplitView` with always-visible history on the left.
- Top-level mode switching is handled by a shared mode picker.
- Input, results, and history are functional but visually flat.
- Liquid Glass is applied mostly as a panel treatment rather than as a broader native macOS hierarchy.

This design covers the next phase: keep all current functionality, but reorganize the app into a more native macOS single-window workbench with wider spacing, clearer hierarchy, and restrained Liquid Glass usage.

## Confirmed Decisions

- Preserve all current calculation features.
- Target only the current OS/toolchain environment already used by the project.
- Use a native macOS visual direction rather than preserving the current migration-stage structure.
- Use a single-window workbench layout.
- Allow layout restructuring rather than only reskinning the current screen.
- Prefer a roomy, polished desktop feel over dense information packing.
- Use sidebar navigation for top-level feature switching.
- Keep history hidden by default instead of always occupying layout space.
- Require manual calculation for network calculation and IPv4/IPv6 translation.
- Use automatic updates for base conversion.
- Write history only for successful manual calculations.
- Apply Liquid Glass in a balanced way: window chrome and key panels get glass hierarchy, content text remains readability-first.
- Keep the app SwiftUI-first and use AppKit only for window-level or desktop-specific gaps.

## Goals

- Make the app feel like a native macOS utility rather than a direct port.
- Preserve current behavior while improving visual hierarchy, interaction flow, and workspace clarity.
- Separate navigation, calculation, results, and history into clearer responsibilities.
- Tighten UI architecture so Core remains domain-only and ViewModel types own UI semantics.
- Leave enough structure for later visual polish without forcing another state-management rewrite.

## Non-Goals

- Do not change calculation semantics or remove any current result fields.
- Do not add persistence, sync, or cross-device history.
- Do not add multiple windows, tabs, or document-based workflows.
- Do not broaden platform support beyond the current macOS target.
- Do not move UI-specific labels, result-row concepts, or clipboard text generation into `IPCalculatorCore`.

## Chosen Product Direction

Three directions were considered during brainstorming:

1. Native workbench
2. Upgrade the existing structure in place
3. Strong-navigation layout with persistent inspector

The selected direction is **Native workbench** because it best matches the confirmed constraints:

- single-window workflow
- native macOS presentation
- roomy layout
- hidden-by-default history
- SwiftUI-first structure with selective AppKit support

This means the app should stop treating all modes as slight variations of one page and instead treat each major function as its own workspace within one coherent window.

## Window Structure

The app should remain a single main window built around a two-region workbench:

- **Sidebar:** narrow, always visible, responsible only for top-level navigation
- **Main workspace:** the active tool surface for the selected feature

Top-level sidebar entries:

- `IP 计算`
- `进制转换`

The toolbar remains light and native. It should include:

- the current workspace title
- a `历史` action
- optional future utility items such as settings/about

History must not occupy permanent main-window space. The default presentation is a toolbar-triggered SwiftUI popover. If that proves too constrained for focus, sizing, or keyboard behavior, the implementation may bridge to a small utility `NSPanel` without changing the rest of the architecture.

The main workspace should be the visual focus of the window. It should not be framed like a web dashboard with many small cards. Instead, it should use a few large surfaces with clear spacing and ordering.

## Workspace Design

### 1. IP Calculation Workspace

The `IP 计算` workspace contains a second-level segmented control in the main area:

- `网段计算`
- `IPv4 / IPv6 互转`

This secondary switch belongs in the main workspace, not the sidebar, so the sidebar remains shallow and stable.

The workspace layout is vertically ordered:

1. workspace header and segmented control
2. input surface
3. result surface

The surfaces should feel like one coherent task flow rather than separate unrelated cards.

#### 1.1 网段计算

Behavior:

- calculation runs only on explicit user action
- trigger methods: `计算` button and Return/Enter
- invalid or incomplete edits do not auto-refresh results

Input surface:

- keeps the current supported input forms
- uses wider native form spacing and clearer placeholders
- keeps the primary action visually obvious but not oversized

Result surface:

- keeps all current result items
- groups results by importance

Recommended grouping:

- **Core results:** 网段, 地址数量, 首个地址, 最后地址
- **Extended results:** C 段数量, but only when the current calculation produces it

Copy actions remain in the result area, not mixed into the input area.

#### 1.2 IPv4 / IPv6 Translation

This area preserves both existing translation flows inside the same workspace family:

- IPv4 network -> IPv6 network generation
- IPv6 address/network -> IPv4 network reverse calculation

Behavior:

- calculation runs only on explicit user action
- trigger methods: `计算` button and Return/Enter

Layout:

- source input fields stay visually grouped
- target output stays in the result surface
- the screen should read as “provide source + receive generated target”, not as a long table

The result surface should clearly emphasize the generated destination network as the primary copy target.

### 2. Base Conversion Workspace

The `进制转换` workspace is independent from the IP workspace and should not reuse the same layout blindly.

Behavior:

- updates automatically on valid input
- never writes to history
- preserves current editing-state protections so typing in one base field does not cause disruptive echo behavior

Layout:

- three primary inputs: binary, decimal, hexadecimal
- currently active field gets the strongest editing emphasis
- the bit grid is promoted from auxiliary debug-style output to a first-class visual control

The bit grid should keep clear grouping by nibble/byte and remain directly clickable. It should visually support the conversion workflow, not appear bolted on underneath it.

## Visual System

The window should follow native macOS conventions rather than web-style custom chrome.

### Glass Placement

Balanced Liquid Glass means:

- **Strongest glass presence:** window chrome, toolbar, sidebar
- **Moderate glass presence:** major workspace surfaces such as input, results, and transient history
- **Minimal glass presence:** row-level content, dense text regions, and detailed result values

Glass is used to express container hierarchy, not to decorate every row.

### Density and Spacing

The target density is intentionally relaxed:

- larger inter-section spacing
- more breathing room around primary controls
- fewer simultaneously visible micro-panels

This is not a dense network engineering console. It is a polished native desktop utility.

### Typography and Controls

- use standard macOS text hierarchy
- keep labels concise
- prefer native controls for segmented picks, text fields, lists, buttons, and copy actions
- avoid oversized hero text or landing-page styling

## Architecture Adjustments

The current app works, but the next UI phase needs cleaner state boundaries than a single broad `CalculatorViewModel`.

### Core Layer

`IPCalculatorCore` remains unchanged in responsibility:

- parse IP input
- calculate network/translation/base-conversion results
- normalize input
- format IP and numeric values
- throw domain errors

Core must not know:

- result-row labels
- Chinese UI section names
- copy-all text
- history display strings

### Features Layer

Replace the single broad workflow state with workspace-oriented models:

- `AppNavigationModel`
  - selected top-level workspace
  - secondary selection inside `IP 计算`
  - history presentation state

- `NetworkWorkspaceViewModel`
  - network-calculation inputs
  - calculate action
  - mapped result groups
  - status and error state
  - copy targets

- `TranslationWorkspaceViewModel`
  - IPv4/IPv6 translation inputs
  - calculate action
  - mapped result groups
  - status and error state
  - copy targets

- `BaseConversionViewModel`
  - active editing field
  - synchronized text state
  - bit-grid value
  - validation state

- `HistoryStore`
  - in-memory manual-calculation history only
  - deduplication
  - maximum-entry policy

This split keeps the UI architecture aligned with the new workbench instead of forcing one model to multiplex every workspace concern.

### UI Layer

SwiftUI should continue to own nearly all view composition:

- sidebar navigation
- main workspace shells
- segmented controls
- input surfaces
- result surfaces
- base conversion layout
- transient history content

AppKit remains optional and narrowly scoped to:

- window configuration details
- toolbar/window behavior not exposed cleanly in SwiftUI
- focus and first-responder refinements where needed
- transient utility-panel behavior only if SwiftUI presentation APIs are insufficient

## Data and Interaction Flow

### Network Calculation Flow

1. User edits fields in the network workspace.
2. UI reflects field-local validation hints but does not recalculate.
3. User clicks `计算` or presses Return.
4. ViewModel validates required inputs and calls Core.
5. Core returns typed results or throws a domain error.
6. ViewModel maps results into grouped result presentation and copy targets.
7. Successful calculation writes one history entry.

### Translation Flow

1. User edits translation inputs.
2. No automatic recalculation occurs.
3. User clicks `计算` or presses Return.
4. ViewModel calls the appropriate Core translation routine.
5. ViewModel maps the generated target network into result groups and copy targets.
6. Successful calculation writes one history entry.

### Base Conversion Flow

1. User edits one field or clicks a bit.
2. ViewModel updates conversion state immediately.
3. Result fields and bit grid stay synchronized.
4. Invalid input remains local to that workspace and does not affect history.

### History Flow

1. User opens history from the toolbar.
2. The transient history surface shows recent manual calculations only.
3. Each entry supports at least:
   - copy result
   - reuse or restore into the active workspace
4. Closing history returns focus to the main workbench.

## Error Handling

Errors should be surfaced at the smallest useful scope.

- **Field-local feedback:** invalid base-conversion input, missing required values while editing
- **Workspace-level message:** calculation failed after an explicit action
- **No global noisy alerting:** avoid modal interruption for normal validation failures

Core still throws stable domain errors. ViewModel maps them into user-facing Chinese messages and decides where they belong in the workspace.

The result area should not keep stale “successful” emphasis when the latest manual calculation fails.

## History Rules

History behavior is fixed as follows:

- only successful manual calculations are recorded
- base conversion never records history
- duplicate entries collapse by primary copy value
- newest entries appear first
- history remains in-memory only

History entries should store reusable calculation summaries rather than view snapshots. They should be stable enough to drive copy and restore actions without depending on current view layout.

## Testing Strategy

UI polish should not reduce behavioral confidence.

### Core Tests

Keep and extend calculation coverage for:

- IPv4 and IPv6 network calculation
- large IPv6 address counts
- translation flows
- input normalization
- base conversion math

### Features Tests

Add focused tests for:

- manual-vs-automatic trigger rules
- history-write policy
- result-group mapping
- copy-text generation
- workspace error mapping
- restore-from-history behavior

### UI Verification

Keep UI verification targeted:

- sidebar navigation switches the correct workspace
- secondary segmented control switches within `IP 计算`
- history presentation opens and closes correctly
- base conversion preserves smooth editing behavior
- manual calculation views do not auto-refresh

## Implementation Sequence

The implementation should proceed in this order:

1. Split current feature state into workspace-oriented models.
2. Refactor the top-level window into sidebar + main workbench structure.
3. Rebuild the `IP 计算` workspace around the new two-surface layout.
4. Rebuild the `进制转换` workspace around automatic conversion and promoted bit-grid presentation.
5. Move history to transient presentation and add restore/copy actions.
6. Apply balanced glass styling and macOS spacing refinements.
7. Add narrow AppKit bridges only for proven gaps.
8. Re-run tests and manual desktop verification.

This order reduces churn by fixing state boundaries before detailed layout work.

## Risks and Mitigations

- **Risk:** UI restructuring accidentally changes calculation behavior.
  **Mitigation:** keep Core unchanged and shift UI semantics into ViewModel-only mapping.

- **Risk:** history becomes less usable when hidden by default.
  **Mitigation:** keep toolbar access obvious and support direct reuse/copy inside the transient history surface.

- **Risk:** overusing glass reduces legibility.
  **Mitigation:** restrict glass to chrome and major surfaces, not row-level details.

- **Risk:** one giant view model survives through incremental edits.
  **Mitigation:** make workspace-state decomposition the first implementation step.

- **Risk:** AppKit usage expands without discipline.
  **Mitigation:** treat AppKit as an exception path tied to specific gaps, not as a second UI framework.

## Acceptance Criteria

The redesign is complete when:

- the app remains functionally equivalent to the current release
- top-level navigation uses a native sidebar for `IP 计算` and `进制转换`
- `IP 计算` uses an in-workspace segmented control for `网段计算` and `IPv4 / IPv6 互转`
- network and translation flows require explicit calculation
- base conversion updates automatically and does not write history
- history is hidden by default and exposed through a transient surface
- only successful manual calculations enter history
- the main window reads as a native macOS workbench with balanced Liquid Glass usage
- Core remains free of UI row, label, and clipboard-text responsibilities

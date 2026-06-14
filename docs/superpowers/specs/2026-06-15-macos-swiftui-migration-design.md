# macOS SwiftUI Migration Design

Date: 2026-06-15

## Context

The current project is an IP address calculator that was originally described as a Python client, then rebuilt as a Tauri v2 + TypeScript desktop app. The current source tree no longer contains Python client code. The active implementation is:

- `src/ipcalc.ts`: IP parsing, network calculation, IPv4/IPv6 mapping, base conversion, formatting, and input normalization.
- `src/main.ts`: DOM UI, mode switching, input normalization during typing, result rendering, copy behavior, and in-memory history.
- `src-tauri/`: a thin Tauri shell with window configuration and basic window permissions.

The migration goal is to replace the Tauri/TypeScript/Rust project with a native macOS app using SwiftUI as the primary UI framework. AppKit should only be used where SwiftUI does not expose enough macOS-specific control.

## Confirmed Decisions

- Preserve all current user-facing functionality.
- Target only the current development machine and OS generation: macOS 26.5.1 with Xcode 26.5.
- Use SwiftUI-first architecture.
- Use macOS 26 SwiftUI Liquid Glass APIs, including `glassEffect`, where appropriate.
- Use AppKit only for platform services or window-level details.
- Replace the existing Tauri project over time; the final repository should be a pure Swift/macOS project.
- Keep the first implementation focused on a single-window desktop utility.

## Goals

The native macOS app must preserve these capabilities:

- IPv4 and IPv6 network calculation with network address, address count, first address, and last address.
- CIDR input, numeric prefix input, and IPv4 dotted subnet mask input.
- IPv4 `/16` through `/24` C-block count display.
- IPv4 network to IPv6 network generation using an IPv6 `/96` prefix.
- IPv6 address or network to IPv4 reverse calculation using the last 32 bits, with optional IPv6 `/96` prefix validation.
- Binary, decimal, and hexadecimal conversion for 32-bit unsigned integers.
- A 32-bit bit grid where clicking a bit toggles the value and updates all base fields.
- Common Chinese input method punctuation normalization and full-width character normalization.
- Copy single result rows, copy all rows, and copy the primary generated network.
- In-memory history with deduplication and a maximum of eight entries.
- Error display for invalid input, invalid prefixes, invalid masks, and out-of-range base conversion values.

## Non-Goals

- Do not preserve the Tauri WebView runtime.
- Do not preserve the CSS-based custom titlebar or pixel-level web UI styling.
- Do not keep Node, Vite, Vitest, Rust, or Tauri as runtime/build dependencies after migration completes.
- Do not add cross-platform support.
- Do not add persistence, menu bar mode, global shortcuts, or advanced distribution work in the first pass.

## Architecture

The app should be split into five layers.

### 1. Core Calculation Layer

This layer is pure Swift and has no dependency on SwiftUI or AppKit.

Responsibilities:

- Parse IPv4 and IPv6 addresses.
- Parse `ADDRESS/PREFIX`, `ADDRESS/MASK`, and two-value address/prefix forms where needed.
- Convert IPv4 dotted subnet masks to prefix lengths and reject host masks or non-contiguous masks.
- Calculate network address, address count, first address, and last address.
- Generate IPv6 networks from IPv4 networks with a validated IPv6 `/96` prefix.
- Reverse IPv6 addresses or networks back to IPv4 networks from the last 32 bits.
- Normalize user input text.
- Convert unsigned 32-bit values between binary, decimal, and hexadecimal.
- Toggle individual bits in a 32-bit value.
- Format result rows and clipboard text.

Data choices:

- Use `UInt32` for IPv4 addresses and 32-bit base conversion.
- Use `UInt128` for IPv6 addresses and IPv6 network math.
- Use typed result structs instead of stringly typed dictionaries.
- Use throwing functions with domain-specific errors that can be mapped to user-facing messages.

### 2. Feature State and ViewModel Layer

This layer owns UI state and calls the Core layer. It should contain no parsing or network math beyond delegating to Core.

Suggested types:

- `CalculatorMode`: `network`, `ipv4ToIpv6`, `ipv6ToIpv4`, `baseConversion`.
- `CalculatorViewModel`: selected mode, current inputs, current result rows, status, copy targets, history, and errors.
- `BaseConversionState`: active base field, current `UInt32` value, field strings, invalid state, and 32-bit display.
- `HistoryStore`: in-memory deduplication and max-eight history behavior.
- `ResultRow`: label, value, and copy affordance metadata.
- `CalculationError`: normalized error cases with Chinese user-facing messages.

### 3. SwiftUI View Layer

SwiftUI owns the main interface.

Suggested views:

- `IPCalculatorApp`: app entry.
- `ContentView`: top-level window layout.
- `ModePickerView`: native segmented mode picker.
- `InputPanelView`: mode-specific input fields.
- `ResultPanelView`: status, result rows, copy buttons, and error display.
- `HistorySidebarView`: in-memory calculation history.
- `BaseConversionView`: binary/decimal/hex inputs plus bit grid.
- `BinaryBitGridView`: 32 clickable bits grouped for readability.

Visual direction:

- Prefer native macOS controls and spacing.
- Use SwiftUI `glassEffect` and system materials for Liquid Glass styling.
- Avoid recreating the current CSS card system.
- Keep text legible over glass backgrounds.
- Use SF Symbols where icons are needed.

### 4. Platform Services Layer

This layer isolates macOS-specific APIs.

Suggested services:

- `ClipboardService`: wraps `NSPasteboard` for copying row values and whole result text.
- `WindowConfigurator`: optional window size/titlebar configuration.
- `VisualEffectHost`: optional AppKit bridge only if SwiftUI glass/material APIs are insufficient for a specific window-level effect.

Rules:

- AppKit should not enter the Core layer.
- AppKit should not be used for ordinary forms, buttons, lists, or state-driven rendering.
- SwiftUI remains the default unless a concrete macOS behavior requires AppKit.

### 5. Tests Layer

Core behavior should be verified before UI migration is considered complete.

Test coverage should include:

- All existing `src/ipcalc.test.ts` calculation cases.
- IPv4 CIDR, numeric prefix, dotted mask, invalid mask, prefix boundaries, and hostmask rejection.
- IPv6 CIDR, numeric prefix, formatting, and invalid prefix behavior.
- IPv4 to IPv6 `/96` generation.
- IPv6 to IPv4 reverse calculation and optional prefix validation.
- Full-width and Chinese punctuation normalization.
- Base conversion across binary, decimal, and hexadecimal.
- Maximum unsigned 32-bit value.
- 32-bit overflow rejection.
- Bit toggle behavior.
- History deduplication and max-eight behavior through ViewModel tests.

Use Swift Testing or XCTest. The Core layer should be testable without launching the app.

## Data Flow

Network modes:

1. User edits input in SwiftUI fields.
2. ViewModel normalizes the field text while preserving a predictable editing experience.
3. User presses Calculate or hits Return.
4. ViewModel calls the relevant Core function.
5. Core returns typed calculation results or throws a typed error.
6. ViewModel maps results to `ResultRow` values and copy targets.
7. SwiftUI updates result, status, copy buttons, and history.

Base conversion mode:

1. User edits one base field or toggles a bit.
2. ViewModel calls Core conversion/toggle logic.
3. ViewModel updates all three field strings and the 32-bit grid.
4. Invalid input marks the active field and exposes an error state.

Copy flow:

1. User clicks a result row, Copy All, or Copy Network.
2. ViewModel chooses the target text.
3. `ClipboardService` writes the text to `NSPasteboard`.
4. ViewModel temporarily updates status/button feedback.

## Error Handling

Core functions should throw structured errors rather than returning partial results.

Error categories:

- Empty required input.
- Invalid IP address.
- Invalid IPv4 octet.
- Invalid IPv6 hextet.
- Invalid prefix length.
- Prefix out of range.
- Invalid IPv4 netmask.
- IPv6 dotted mask rejection.
- IPv4-to-IPv6 called with a non-IPv4 address.
- IPv6-to-IPv4 called with prefix shorter than `/96`.
- IPv6 `/96` prefix mismatch.
- Base conversion invalid digit.
- Base conversion value outside `UInt32`.
- Bit index out of range.

The UI should show clear Chinese messages and avoid exposing Swift type names or debug output.

## Migration Strategy

The migration should be done in this order:

1. Create the Swift/Xcode project structure.
2. Implement the Core calculation layer and equivalent tests.
3. Implement the ViewModel layer and history/copy state tests.
4. Build the SwiftUI views around the tested ViewModel.
5. Apply Liquid Glass styling with SwiftUI `glassEffect` and system materials.
6. Add AppKit bridges only for concrete platform gaps.
7. Verify the app manually on macOS 26.5.1.
8. Remove Tauri, Rust, TypeScript, Node, and web build artifacts once the native app reaches feature parity.
9. Update README and third-party notices.

## Risks and Mitigations

- Risk: subtle behavior drift during TypeScript-to-Swift algorithm migration.
  Mitigation: port existing unit tests first and keep expected output identical.

- Risk: overusing glass effects hurts readability.
  Mitigation: use native controls and glass for hierarchy, not as decoration on every surface.

- Risk: AppKit creep makes the app harder to reason about.
  Mitigation: keep AppKit isolated behind small services and bridges.

- Risk: deleting Tauri files too early removes useful behavioral reference.
  Mitigation: keep old implementation until Swift tests and manual UI checks pass.

- Risk: repository history is currently incomplete after `.git` repair.
  Mitigation: keep migration commits focused and avoid unrelated cleanup until the native app is verified.

## Acceptance Criteria

The migration is complete when:

- The native macOS app builds with Xcode 26.5 on macOS 26.5.1.
- All current calculation features are available in the SwiftUI app.
- Core Swift tests cover the current TypeScript calculation behavior.
- Result rows, copy-all, copy-network, and history work.
- The base conversion mode supports synchronized fields and 32-bit bit toggling.
- The UI uses native macOS controls and Liquid Glass styling.
- The app no longer requires Node, Tauri, Rust, Vite, or a WebView runtime.
- README reflects the new SwiftUI/AppKit architecture.

# macOS Native Workbench UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current migration-stage SwiftUI screen with a native macOS single-window workbench that preserves all existing functionality while moving to sidebar navigation, hidden-by-default history, mixed manual/automatic calculation triggers, and balanced Liquid Glass styling.

**Architecture:** Keep `IPCalculatorCore` unchanged and move UI semantics into new workspace-oriented `IPCalculatorFeatures` models. Switch the app shell to a `CalculatorWorkbenchViewModel` that coordinates navigation, manual calculation history, and restore actions, then rebuild the SwiftUI layer around dedicated workspace views instead of the current shared mode picker.

**Tech Stack:** Swift 6.2, SwiftUI, Observation, AppKit clipboard APIs, Swift Testing, Swift Package Manager, macOS 26.

---

## File Structure

- Modify: `Sources/IPCalculatorFeatures/CalculatorModels.swift`
  - Add top-level workbench enums, result-section models, translation direction, and history restore payloads while keeping existing types available during the transition.
- Create: `Sources/IPCalculatorFeatures/AppNavigationModel.swift`
  - Own top-level workspace selection, selected IP workspace mode, and history popover state.
- Modify: `Sources/IPCalculatorFeatures/HistoryStore.swift`
  - Add `add(entry:)` support for typed history entries and keep legacy add helpers temporarily for incremental migration.
- Create: `Sources/IPCalculatorFeatures/NetworkWorkspaceViewModel.swift`
  - Own network-calculation inputs, manual calculate action, grouped result rows, and history-entry generation.
- Create: `Sources/IPCalculatorFeatures/TranslationWorkspaceViewModel.swift`
  - Own translation direction, manual calculate action, grouped result rows, and history-entry generation for both translation flows.
- Create: `Sources/IPCalculatorFeatures/BaseConversionViewModel.swift`
  - Replace the old value-type conversion state with an observable workspace model that keeps active-field editing stable.
- Create: `Sources/IPCalculatorFeatures/CalculatorWorkbenchViewModel.swift`
  - Coordinate navigation, shared history, restore actions, and dispatching of manual calculations.
- Delete after migration: `Sources/IPCalculatorFeatures/CalculatorViewModel.swift`
  - Remove the old monolithic UI model after the new workbench is wired up.
- Delete after migration: `Sources/IPCalculatorFeatures/BaseConversionState.swift`
  - Remove the old value-type conversion state after the new workspace model is adopted.
- Modify: `Sources/IPNetworkCalculator/ContentView.swift`
  - Switch the app entry screen from the legacy shared mode layout to the workbench shell.
- Create: `Sources/IPNetworkCalculator/SidebarNavigationView.swift`
  - Render top-level `IP 计算` and `进制转换` navigation.
- Create: `Sources/IPNetworkCalculator/HistoryPopoverView.swift`
  - Present transient history with copy and restore actions.
- Create: `Sources/IPNetworkCalculator/IPWorkspaceView.swift`
  - Render the `IP 计算` workbench shell and second-level segmented control.
- Create: `Sources/IPNetworkCalculator/IPWorkspacePickerView.swift`
  - Render the `网段计算` / `IPv4 / IPv6 互转` segmented control.
- Create: `Sources/IPNetworkCalculator/NetworkWorkspaceView.swift`
  - Render the network-calculation form and result surface.
- Create: `Sources/IPNetworkCalculator/TranslationWorkspaceView.swift`
  - Render the translation workspace form and result surface.
- Create: `Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift`
  - Render the inner `V4 -> V6` / `V6 -> V4` segmented control inside the translation workspace.
- Modify: `Sources/IPNetworkCalculator/ResultPanelView.swift`
  - Generalize result rendering for grouped sections and shared copy behavior.
- Modify: `Sources/IPNetworkCalculator/BaseConversionView.swift`
  - Bind to the new conversion workspace model and adopt the new roomy workbench layout.
- Modify: `Sources/IPNetworkCalculator/BinaryBitGridView.swift`
  - Improve grouping and sizing so the bit grid reads as a first-class control.
- Modify: `Sources/IPNetworkCalculator/GlassStyle.swift`
  - Provide separate modifiers for workspace surfaces, chrome, and transient panels.
- Modify: `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`
  - Keep the same app entry but tune the default window size for the wider workbench.
- Delete after migration: `Sources/IPNetworkCalculator/ModePickerView.swift`
  - Remove the old top-level mode picker after the sidebar shell is active.
- Delete after migration: `Sources/IPNetworkCalculator/InputPanelView.swift`
  - Remove the legacy shared input panel after dedicated workspace views replace it.
- Delete after migration: `Sources/IPNetworkCalculator/HistorySidebarView.swift`
  - Remove the always-visible history list after the popover is active.
- Modify/Create tests:
  - `Tests/IPCalculatorFeaturesTests/AppNavigationModelTests.swift`
  - `Tests/IPCalculatorFeaturesTests/HistoryStoreTests.swift`
  - `Tests/IPCalculatorFeaturesTests/NetworkWorkspaceViewModelTests.swift`
  - `Tests/IPCalculatorFeaturesTests/TranslationWorkspaceViewModelTests.swift`
  - `Tests/IPCalculatorFeaturesTests/BaseConversionViewModelTests.swift`
  - `Tests/IPCalculatorFeaturesTests/CalculatorWorkbenchViewModelTests.swift`
- Delete after migration: `Tests/IPCalculatorFeaturesTests/CalculatorViewModelTests.swift`
  - Remove old monolithic-view-model tests after the new workspace tests cover the same behavior.

### Task 1: Add Navigation and Typed History Foundations

**Files:**
- Modify: `Sources/IPCalculatorFeatures/CalculatorModels.swift`
- Modify: `Sources/IPCalculatorFeatures/HistoryStore.swift`
- Create: `Sources/IPCalculatorFeatures/AppNavigationModel.swift`
- Modify: `Tests/IPCalculatorFeaturesTests/HistoryStoreTests.swift`
- Create: `Tests/IPCalculatorFeaturesTests/AppNavigationModelTests.swift`

- [ ] **Step 1: Write the failing tests for navigation defaults and typed history restore targets**

```swift
// Tests/IPCalculatorFeaturesTests/AppNavigationModelTests.swift
import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func navigationModelDefaultsToIPWorkspaceWithHistoryClosed() {
    let model = AppNavigationModel()

    #expect(model.selectedWorkspace == .ipCalculation)
    #expect(model.selectedIPMode == .network)
    #expect(model.isHistoryPresented == false)
}

// Tests/IPCalculatorFeaturesTests/HistoryStoreTests.swift
import Testing
@testable import IPCalculatorFeatures

@Test
func dedupesTypedHistoryEntriesAndKeepsRestoreTarget() {
    var store = HistoryStore()
    store.add(
        entry: HistoryEntry(
            title: "192.168.1.0/24",
            subtitle: "网段计算 · 192.168.1.10/24",
            copyText: "192.168.1.0/24",
            restoreTarget: .network(input: "192.168.1.10/24")
        )
    )
    store.add(
        entry: HistoryEntry(
            title: "192.168.1.0/24",
            subtitle: "网段计算 · 192.168.1.10/24",
            copyText: "192.168.1.0/24",
            restoreTarget: .network(input: "192.168.1.10/24")
        )
    )

    #expect(store.entries.count == 1)
    #expect(store.entries.first?.restoreTarget == .network(input: "192.168.1.10/24"))
}
```

- [ ] **Step 2: Run the tests to verify the new types do not exist yet**

Run:

```bash
swift test
```

Expected: FAIL with compiler errors for `AppNavigationModel`, `AppWorkspace`, `IPWorkspaceMode`, and `HistoryRestoreTarget`.

- [ ] **Step 3: Implement additive navigation enums, history payloads, and the observable navigation model**

```swift
// Sources/IPCalculatorFeatures/CalculatorModels.swift
import Foundation

public enum AppWorkspace: String, CaseIterable, Identifiable, Sendable {
    case ipCalculation
    case baseConversion

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .ipCalculation:
            "IP 计算"
        case .baseConversion:
            "进制转换"
        }
    }
}

public enum IPWorkspaceMode: String, CaseIterable, Identifiable, Sendable {
    case network
    case translation

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .network:
            "网段计算"
        case .translation:
            "IPv4 / IPv6 互转"
        }
    }
}

public enum TranslationDirection: String, CaseIterable, Identifiable, Sendable {
    case ipv4ToIPv6
    case ipv6ToIPv4

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .ipv4ToIPv6:
            "V4 -> V6"
        case .ipv6ToIPv4:
            "V6 -> V4"
        }
    }
}

public enum HistoryRestoreTarget: Equatable, Sendable {
    case network(input: String)
    case ipv4ToIPv6(ipv4Input: String, ipv6PrefixInput: String)
    case ipv6ToIPv4(ipv6Input: String, ipv6PrefixInput: String)
}

public struct ResultSection: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public var title: String
    public var rows: [ResultRow]

    public init(title: String, rows: [ResultRow]) {
        self.title = title
        self.rows = rows
    }
}

public struct HistoryEntry: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public var title: String
    public var subtitle: String
    public var copyText: String
    public var restoreTarget: HistoryRestoreTarget?

    public init(title: String, subtitle: String, copyText: String, restoreTarget: HistoryRestoreTarget? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.copyText = copyText
        self.restoreTarget = restoreTarget
    }
}

// Sources/IPCalculatorFeatures/HistoryStore.swift
import Foundation

public struct HistoryStore: Equatable, Sendable {
    public private(set) var entries: [HistoryEntry] = []
    public var maxEntries = 8

    public init() {}

    public mutating func add(entry: HistoryEntry) {
        guard !entry.copyText.isEmpty else { return }

        entries.removeAll { $0.copyText == entry.copyText }
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeSubrange(maxEntries..<entries.count)
        }
    }

    public mutating func add(title: String, subtitle: String, copyText: String) {
        add(entry: HistoryEntry(title: title, subtitle: subtitle, copyText: copyText))
    }
}

// Sources/IPCalculatorFeatures/AppNavigationModel.swift
import Observation

@MainActor
@Observable
public final class AppNavigationModel {
    public var selectedWorkspace: AppWorkspace = .ipCalculation
    public var selectedIPMode: IPWorkspaceMode = .network
    public var isHistoryPresented = false

    public init() {}
}
```

- [ ] **Step 4: Run the feature tests and keep the legacy app behavior green**

Run:

```bash
swift test
```

Expected: PASS for the new navigation/history tests and PASS for the existing legacy tests.

- [ ] **Step 5: Commit the foundation work**

```bash
git add Sources/IPCalculatorFeatures/CalculatorModels.swift Sources/IPCalculatorFeatures/HistoryStore.swift Sources/IPCalculatorFeatures/AppNavigationModel.swift Tests/IPCalculatorFeaturesTests/HistoryStoreTests.swift Tests/IPCalculatorFeaturesTests/AppNavigationModelTests.swift
git commit -m "feat: add workbench navigation and typed history models"
```

### Task 2: Add Dedicated Network and Translation Workspace Models

**Files:**
- Create: `Sources/IPCalculatorFeatures/NetworkWorkspaceViewModel.swift`
- Create: `Sources/IPCalculatorFeatures/TranslationWorkspaceViewModel.swift`
- Create: `Tests/IPCalculatorFeaturesTests/NetworkWorkspaceViewModelTests.swift`
- Create: `Tests/IPCalculatorFeaturesTests/TranslationWorkspaceViewModelTests.swift`

- [ ] **Step 1: Write the failing tests for grouped result mapping and manual history-entry generation**

```swift
// Tests/IPCalculatorFeaturesTests/NetworkWorkspaceViewModelTests.swift
import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func networkWorkspaceBuildsGroupedRowsAndHistoryEntry() {
    let viewModel = NetworkWorkspaceViewModel()
    viewModel.networkInput = "192.168.1.10/24"

    let entry = viewModel.calculate()

    #expect(viewModel.statusText == "192.168.1.0/24")
    #expect(viewModel.resultSections.map(\.title) == ["核心结果", "扩展结果"])
    #expect(viewModel.resultSections.first?.rows.map(\.label) == ["网段", "地址数量", "首个地址", "最后地址"])
    #expect(viewModel.primaryCopyLabel == "网段")
    #expect(entry?.restoreTarget == .network(input: "192.168.1.10/24"))
}

// Tests/IPCalculatorFeaturesTests/TranslationWorkspaceViewModelTests.swift
import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func translationWorkspaceBuildsIpv4ToIpv6ResultAndHistoryEntry() {
    let viewModel = TranslationWorkspaceViewModel()
    viewModel.direction = .ipv4ToIPv6
    viewModel.ipv4Input = "48.235.24.0/30"
    viewModel.ipv6PrefixInput = "2001:db8::"

    let entry = viewModel.calculate()

    #expect(viewModel.resultSections.map(\.title) == ["生成结果", "地址范围"])
    #expect(viewModel.primaryCopyLabel == "IPv6 网段")
    #expect(viewModel.primaryCopyText == "2001:db8::30eb:1800/126")
    #expect(entry?.restoreTarget == .ipv4ToIPv6(ipv4Input: "48.235.24.0/30", ipv6PrefixInput: "2001:db8::"))
}

@MainActor
@Test
func translationWorkspaceBuildsIpv6ToIpv4ResultAndHistoryEntry() {
    let viewModel = TranslationWorkspaceViewModel()
    viewModel.direction = .ipv6ToIPv4
    viewModel.ipv6Input = "2001:db8::30eb:1800/126"
    viewModel.ipv6ReversePrefixInput = "2001:db8::"

    let entry = viewModel.calculate()

    #expect(viewModel.statusText == "IPv4 网段已反算")
    #expect(viewModel.primaryCopyLabel == "IPv4 网段")
    #expect(viewModel.primaryCopyText == "48.235.24.0/30")
    #expect(entry?.restoreTarget == .ipv6ToIPv4(ipv6Input: "2001:db8::30eb:1800/126", ipv6PrefixInput: "2001:db8::"))
}
```

- [ ] **Step 2: Run the test suite and verify the workspace view models are still missing**

Run:

```bash
swift test
```

Expected: FAIL with compiler errors for `NetworkWorkspaceViewModel`, `TranslationWorkspaceViewModel`, `resultSections`, and the new copy-label properties.

- [ ] **Step 3: Implement the dedicated workspace models by lifting logic out of the legacy monolithic view model**

```swift
// Sources/IPCalculatorFeatures/NetworkWorkspaceViewModel.swift
import Foundation
import IPCalculatorCore
import Observation

@MainActor
@Observable
public final class NetworkWorkspaceViewModel {
    public var networkInput = ""
    public var resultSections: [ResultSection] = []
    public var statusText = "等待输入..."
    public var errorMessage: String?
    public var copyAllText = ""
    public var primaryCopyText = ""
    public var primaryCopyLabel = "网段"

    public init() {}

    @discardableResult
    public func calculate() -> HistoryEntry? {
        resultSections = []
        errorMessage = nil
        copyAllText = ""
        primaryCopyText = ""

        do {
            let raw = InputNormalizer.normalizeFieldText(networkInput)
            guard !raw.isEmpty else {
                throw IPCalculatorError.emptyInput("请输入地址和前缀或掩码，例如 10.0.0.1/20")
            }

            let input = try NetworkCalculator.parseInput([raw])
            let result = try NetworkCalculator.calculate(input)

            let coreRows = [
                ResultRow(label: "网段", value: result.network, isPrimaryCopyTarget: true),
                ResultRow(label: "地址数量", value: result.addressCount),
                ResultRow(label: "首个地址", value: result.firstAddress),
                ResultRow(label: "最后地址", value: result.lastAddress)
            ]
            var sections = [ResultSection(title: "核心结果", rows: coreRows)]
            if let classCCount = result.classCCount {
                sections.append(
                    ResultSection(title: "扩展结果", rows: [ResultRow(label: "C段数量", value: classCCount)])
                )
            }

            resultSections = sections
            copyAllText = sections.flatMap(\.rows).map { "\($0.label): \($0.value)" }.joined(separator: "\n")
            primaryCopyText = result.network
            primaryCopyLabel = "网段"
            statusText = result.network

            return HistoryEntry(
                title: result.network,
                subtitle: "网段计算 · \(result.network)",
                copyText: result.network,
                restoreTarget: .network(input: raw)
            )
        } catch let error as IPCalculatorError {
            statusText = "错误"
            errorMessage = error.userMessage
            return nil
        } catch {
            statusText = "错误"
            errorMessage = String(describing: error)
            return nil
        }
    }

    public func restore(input: String) {
        networkInput = input
    }
}

// Sources/IPCalculatorFeatures/TranslationWorkspaceViewModel.swift
import Foundation
import IPCalculatorCore
import Observation

@MainActor
@Observable
public final class TranslationWorkspaceViewModel {
    public var direction: TranslationDirection = .ipv4ToIPv6
    public var ipv4Input = ""
    public var ipv6PrefixInput = ""
    public var ipv6Input = ""
    public var ipv6ReversePrefixInput = ""
    public var resultSections: [ResultSection] = []
    public var statusText = "等待输入..."
    public var errorMessage: String?
    public var copyAllText = ""
    public var primaryCopyText = ""
    public var primaryCopyLabel = ""

    public init() {}

    @discardableResult
    public func calculate() -> HistoryEntry? {
        resultSections = []
        errorMessage = nil
        copyAllText = ""
        primaryCopyText = ""

        do {
            switch direction {
            case .ipv4ToIPv6:
                return try calculateIPv4ToIPv6()
            case .ipv6ToIPv4:
                return try calculateIPv6ToIPv4()
            }
        } catch let error as IPCalculatorError {
            statusText = "错误"
            errorMessage = error.userMessage
            return nil
        } catch {
            statusText = "错误"
            errorMessage = String(describing: error)
            return nil
        }
    }

    public func restore(direction: TranslationDirection, ipv4Input: String = "", ipv6PrefixInput: String = "", ipv6Input: String = "", ipv6ReversePrefixInput: String = "") {
        self.direction = direction
        self.ipv4Input = ipv4Input
        self.ipv6PrefixInput = ipv6PrefixInput
        self.ipv6Input = ipv6Input
        self.ipv6ReversePrefixInput = ipv6ReversePrefixInput
    }

    private func calculateIPv4ToIPv6() throws -> HistoryEntry {
        let ipv4Raw = InputNormalizer.normalizeFieldText(ipv4Input)
        let prefixRaw = InputNormalizer.normalizeFieldText(ipv6PrefixInput)
        guard !ipv4Raw.isEmpty else {
            throw IPCalculatorError.emptyInput("请输入 IPv4 网段，例如 48.235.24.0/30")
        }
        guard !prefixRaw.isEmpty else {
            throw IPCalculatorError.emptyInput("请输入 IPv6 前 96 位，例如 2001:db8::")
        }

        let input = try NetworkCalculator.parseInput([ipv4Raw])
        let result = try NetworkCalculator.generateIPv6FromIPv4(input, ipv6PrefixText: prefixRaw)
        let generationRows = [
            ResultRow(label: "IPv4 网段", value: result.ipv4Network),
            ResultRow(label: "IPv6 前缀", value: result.ipv6Prefix),
            ResultRow(label: "IPv6 网段", value: result.ipv6Network, isPrimaryCopyTarget: true)
        ]
        let rangeRows = [
            ResultRow(label: "地址数量", value: result.addressCount),
            ResultRow(label: "首个地址", value: result.firstAddress),
            ResultRow(label: "最后地址", value: result.lastAddress)
        ]

        resultSections = [
            ResultSection(title: "生成结果", rows: generationRows),
            ResultSection(title: "地址范围", rows: rangeRows)
        ]
        copyAllText = resultSections.flatMap(\.rows).map { "\($0.label): \($0.value)" }.joined(separator: "\n")
        primaryCopyText = result.ipv6Network
        primaryCopyLabel = "IPv6 网段"
        statusText = "IPv6 网段已生成"

        return HistoryEntry(
            title: result.ipv6Network,
            subtitle: "V4 -> V6 · \(result.ipv4Network)",
            copyText: result.ipv6Network,
            restoreTarget: .ipv4ToIPv6(ipv4Input: ipv4Raw, ipv6PrefixInput: prefixRaw)
        )
    }

    private func calculateIPv6ToIPv4() throws -> HistoryEntry {
        let ipv6Raw = InputNormalizer.normalizeFieldText(ipv6Input)
        let prefixRaw = InputNormalizer.normalizeFieldText(ipv6ReversePrefixInput)
        guard !ipv6Raw.isEmpty else {
            throw IPCalculatorError.emptyInput("请输入 IPv6 地址或网段，例如 2001:db8::30eb:1800/126")
        }

        let result = try NetworkCalculator.generateIPv4FromIPv6(ipv6Raw, ipv6PrefixText: prefixRaw)
        let generationRows = [
            ResultRow(label: "IPv6 前缀", value: result.ipv6Prefix),
            ResultRow(label: "IPv6 网段", value: result.ipv6Network),
            ResultRow(label: "IPv4 网段", value: result.ipv4Network, isPrimaryCopyTarget: true)
        ]
        let rangeRows = [
            ResultRow(label: "地址数量", value: result.addressCount),
            ResultRow(label: "首个 IPv4", value: result.firstAddress),
            ResultRow(label: "最后 IPv4", value: result.lastAddress)
        ]

        resultSections = [
            ResultSection(title: "生成结果", rows: generationRows),
            ResultSection(title: "地址范围", rows: rangeRows)
        ]
        copyAllText = resultSections.flatMap(\.rows).map { "\($0.label): \($0.value)" }.joined(separator: "\n")
        primaryCopyText = result.ipv4Network
        primaryCopyLabel = "IPv4 网段"
        statusText = "IPv4 网段已反算"

        return HistoryEntry(
            title: result.ipv4Network,
            subtitle: "V6 -> V4 · \(result.ipv6Network)",
            copyText: result.ipv4Network,
            restoreTarget: .ipv6ToIPv4(ipv6Input: ipv6Raw, ipv6PrefixInput: prefixRaw)
        )
    }
}
```

- [ ] **Step 4: Run the test suite and verify the new workspace models pass without breaking the legacy screen**

Run:

```bash
swift test
```

Expected: PASS for `NetworkWorkspaceViewModelTests`, `TranslationWorkspaceViewModelTests`, and the existing legacy tests.

- [ ] **Step 5: Commit the dedicated workspace models**

```bash
git add Sources/IPCalculatorFeatures/NetworkWorkspaceViewModel.swift Sources/IPCalculatorFeatures/TranslationWorkspaceViewModel.swift Tests/IPCalculatorFeaturesTests/NetworkWorkspaceViewModelTests.swift Tests/IPCalculatorFeaturesTests/TranslationWorkspaceViewModelTests.swift
git commit -m "feat: add dedicated IP workspace view models"
```

### Task 3: Add the Base Conversion Workspace Model and Workbench Coordinator

**Files:**
- Create: `Sources/IPCalculatorFeatures/BaseConversionViewModel.swift`
- Create: `Sources/IPCalculatorFeatures/CalculatorWorkbenchViewModel.swift`
- Create: `Tests/IPCalculatorFeaturesTests/BaseConversionViewModelTests.swift`
- Create: `Tests/IPCalculatorFeaturesTests/CalculatorWorkbenchViewModelTests.swift`

- [ ] **Step 1: Write the failing tests for automatic base conversion and manual-history coordination**

```swift
// Tests/IPCalculatorFeaturesTests/BaseConversionViewModelTests.swift
import IPCalculatorCore
import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func baseConversionWorkspacePreservesActiveFieldWhileUpdatingOtherBases() {
    let viewModel = BaseConversionViewModel()
    viewModel.update(text: "0xFF", base: .hexadecimal)

    #expect(viewModel.hexadecimalText == "0xFF")
    #expect(viewModel.decimalText == "255")
    #expect(viewModel.binaryText == "11111111")
    #expect(viewModel.invalidBase == nil)
}

@MainActor
@Test
func baseConversionWorkspaceTracksInvalidActiveField() {
    let viewModel = BaseConversionViewModel()
    viewModel.update(text: "102", base: .binary)

    #expect(viewModel.invalidBase == .binary)
    #expect(viewModel.errorMessage == "二进制只能包含 0 和 1")
}

// Tests/IPCalculatorFeaturesTests/CalculatorWorkbenchViewModelTests.swift
import IPCalculatorCore
import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func workbenchWritesHistoryOnlyForManualIpCalculations() {
    let workbench = CalculatorWorkbenchViewModel()
    workbench.networkWorkspace.networkInput = "192.168.1.10/24"

    workbench.calculateCurrentIPWorkspace()
    #expect(workbench.history.entries.count == 1)

    workbench.navigation.selectedWorkspace = .baseConversion
    workbench.baseConversionWorkspace.update(text: "255", base: .decimal)
    #expect(workbench.history.entries.count == 1)
}

@MainActor
@Test
func workbenchRestoresTranslationHistoryIntoTheCorrectWorkspace() {
    let workbench = CalculatorWorkbenchViewModel()
    let entry = HistoryEntry(
        title: "2001:db8::30eb:1800/126",
        subtitle: "V4 -> V6 · 48.235.24.0/30",
        copyText: "2001:db8::30eb:1800/126",
        restoreTarget: .ipv4ToIPv6(ipv4Input: "48.235.24.0/30", ipv6PrefixInput: "2001:db8::")
    )

    workbench.restore(entry)

    #expect(workbench.navigation.selectedWorkspace == .ipCalculation)
    #expect(workbench.navigation.selectedIPMode == .translation)
    #expect(workbench.translationWorkspace.direction == .ipv4ToIPv6)
    #expect(workbench.translationWorkspace.ipv4Input == "48.235.24.0/30")
    #expect(workbench.translationWorkspace.ipv6PrefixInput == "2001:db8::")
}
```

- [ ] **Step 2: Run the test suite and verify the new workbench coordination layer is still missing**

Run:

```bash
swift test
```

Expected: FAIL with compiler errors for `BaseConversionViewModel`, `CalculatorWorkbenchViewModel`, `calculateCurrentIPWorkspace()`, and `restore(_:)`.

- [ ] **Step 3: Implement the observable base-conversion workspace and the thin workbench coordinator**

```swift
// Sources/IPCalculatorFeatures/BaseConversionViewModel.swift
import Foundation
import IPCalculatorCore
import Observation

@MainActor
@Observable
public final class BaseConversionViewModel {
    public var binaryText = ""
    public var decimalText = ""
    public var hexadecimalText = ""
    public var binary32 = String(repeating: "0", count: 32)
    public var value: UInt32 = 0
    public var hasValue = false
    public var invalidBase: NumberBase?
    public var errorMessage: String?

    public init() {}

    public func update(text: String, base: NumberBase) {
        let normalizedText = InputNormalizer.normalizeBaseNumberText(text)
        setText(normalizedText, for: base)

        do {
            if normalizedText.isEmpty {
                clear()
                return
            }

            let result = try BaseConverter.convert(normalizedText, base: base)
            apply(result: result, activeBase: base, activeText: normalizedText)
        } catch let error as IPCalculatorError {
            invalidBase = base
            errorMessage = error.userMessage
        } catch {
            invalidBase = base
            errorMessage = String(describing: error)
        }
    }

    public func toggle(bitIndex: Int) {
        do {
            let result = try BaseConverter.toggleBit(value: value, bitIndex: bitIndex)
            apply(result: result, activeBase: nil, activeText: nil)
        } catch let error as IPCalculatorError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func clear() {
        binaryText = ""
        decimalText = ""
        hexadecimalText = ""
        binary32 = String(repeating: "0", count: 32)
        value = 0
        hasValue = false
        invalidBase = nil
        errorMessage = nil
    }

    private func setText(_ text: String, for base: NumberBase) {
        switch base {
        case .binary:
            binaryText = text
        case .decimal:
            decimalText = text
        case .hexadecimal:
            hexadecimalText = text
        }
    }

    private func apply(result: BaseConversionResult, activeBase: NumberBase?, activeText: String?) {
        value = result.value
        hasValue = true
        binaryText = activeBase == .binary ? activeText ?? result.binary : result.binary
        decimalText = activeBase == .decimal ? activeText ?? result.decimal : result.decimal
        hexadecimalText = activeBase == .hexadecimal ? activeText ?? result.hexadecimal : result.hexadecimal
        binary32 = result.binary32
        invalidBase = nil
        errorMessage = nil
    }
}

// Sources/IPCalculatorFeatures/CalculatorWorkbenchViewModel.swift
import Observation

@MainActor
@Observable
public final class CalculatorWorkbenchViewModel {
    public var navigation = AppNavigationModel()
    public var history = HistoryStore()
    public var networkWorkspace = NetworkWorkspaceViewModel()
    public var translationWorkspace = TranslationWorkspaceViewModel()
    public var baseConversionWorkspace = BaseConversionViewModel()

    public init() {}

    public var windowTitle: String {
        switch navigation.selectedWorkspace {
        case .ipCalculation:
            "IP 计算"
        case .baseConversion:
            "进制转换"
        }
    }

    public func calculateCurrentIPWorkspace() {
        let entry: HistoryEntry?
        switch navigation.selectedIPMode {
        case .network:
            entry = networkWorkspace.calculate()
        case .translation:
            entry = translationWorkspace.calculate()
        }

        if let entry {
            history.add(entry: entry)
        }
    }

    public func restore(_ entry: HistoryEntry) {
        guard let restoreTarget = entry.restoreTarget else { return }

        navigation.selectedWorkspace = .ipCalculation
        navigation.isHistoryPresented = false

        switch restoreTarget {
        case .network(let input):
            navigation.selectedIPMode = .network
            networkWorkspace.restore(input: input)
        case .ipv4ToIPv6(let ipv4Input, let ipv6PrefixInput):
            navigation.selectedIPMode = .translation
            translationWorkspace.restore(
                direction: .ipv4ToIPv6,
                ipv4Input: ipv4Input,
                ipv6PrefixInput: ipv6PrefixInput
            )
        case .ipv6ToIPv4(let ipv6Input, let ipv6PrefixInput):
            navigation.selectedIPMode = .translation
            translationWorkspace.restore(
                direction: .ipv6ToIPv4,
                ipv6Input: ipv6Input,
                ipv6ReversePrefixInput: ipv6PrefixInput
            )
        }
    }
}
```

- [ ] **Step 4: Run the test suite and verify history policy and restore behavior are covered**

Run:

```bash
swift test
```

Expected: PASS for the new workbench and base-conversion tests, while the legacy app still builds against the old view models.

- [ ] **Step 5: Commit the new workbench coordination layer**

```bash
git add Sources/IPCalculatorFeatures/BaseConversionViewModel.swift Sources/IPCalculatorFeatures/CalculatorWorkbenchViewModel.swift Tests/IPCalculatorFeaturesTests/BaseConversionViewModelTests.swift Tests/IPCalculatorFeaturesTests/CalculatorWorkbenchViewModelTests.swift
git commit -m "feat: add workbench coordinator and base conversion workspace"
```

### Task 4: Replace the Legacy Screen with the New Workbench UI

**Files:**
- Modify: `Sources/IPNetworkCalculator/ContentView.swift`
- Create: `Sources/IPNetworkCalculator/SidebarNavigationView.swift`
- Create: `Sources/IPNetworkCalculator/HistoryPopoverView.swift`
- Create: `Sources/IPNetworkCalculator/IPWorkspaceView.swift`
- Create: `Sources/IPNetworkCalculator/IPWorkspacePickerView.swift`
- Create: `Sources/IPNetworkCalculator/NetworkWorkspaceView.swift`
- Create: `Sources/IPNetworkCalculator/TranslationWorkspaceView.swift`
- Create: `Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift`
- Modify: `Sources/IPNetworkCalculator/ResultPanelView.swift`
- Modify: `Sources/IPNetworkCalculator/BaseConversionView.swift`
- Modify: `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`

- [ ] **Step 1: Wire the app shell to the new workbench types and let the build fail on missing views**

```swift
// Sources/IPNetworkCalculator/ContentView.swift
import SwiftUI
import IPCalculatorFeatures

struct ContentView: View {
    @State private var workbench = CalculatorWorkbenchViewModel()

    var body: some View {
        @Bindable var workbench = workbench

        NavigationSplitView {
            SidebarNavigationView(selectedWorkspace: $workbench.navigation.selectedWorkspace)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            Group {
                switch workbench.navigation.selectedWorkspace {
                case .ipCalculation:
                    IPWorkspaceView(workbench: workbench)
                case .baseConversion:
                    BaseConversionView(viewModel: workbench.baseConversionWorkspace)
                }
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(workbench.windowTitle).font(.headline)
                }
                ToolbarItem {
                    Button {
                        workbench.navigation.isHistoryPresented.toggle()
                    } label: {
                        Label("历史", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }
                    .popover(isPresented: $workbench.navigation.isHistoryPresented) {
                        HistoryPopoverView(
                            entries: workbench.history.entries,
                            onCopy: { ClipboardService.copy($0) },
                            onRestore: workbench.restore
                        )
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Run the build and verify the new workspace views are still missing**

Run:

```bash
swift build
```

Expected: FAIL with compiler errors for `SidebarNavigationView`, `IPWorkspaceView`, `HistoryPopoverView`, and the new `BaseConversionView(viewModel:)` signature.

- [ ] **Step 3: Create the new workbench views and switch result rendering to grouped sections**

```swift
// Sources/IPNetworkCalculator/SidebarNavigationView.swift
import SwiftUI
import IPCalculatorFeatures

struct SidebarNavigationView: View {
    @Binding var selectedWorkspace: AppWorkspace

    var body: some View {
        List(AppWorkspace.allCases, selection: $selectedWorkspace) { workspace in
            Label(workspace.title, systemImage: workspace == .ipCalculation ? "point.3.connected.trianglepath.dotted" : "switch.2")
                .tag(workspace)
        }
        .listStyle(.sidebar)
    }
}

// Sources/IPNetworkCalculator/HistoryPopoverView.swift
import SwiftUI
import IPCalculatorFeatures

struct HistoryPopoverView: View {
    let entries: [HistoryEntry]
    let onCopy: (String) -> Void
    let onRestore: (HistoryEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史记录").font(.headline)
            if entries.isEmpty {
                Text("暂无历史记录").foregroundStyle(.secondary)
            } else {
                List(entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.title)
                            .font(.system(.body, design: .monospaced).bold())
                        Text(entry.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("复制") { onCopy(entry.copyText) }
                            Button("恢复") { onRestore(entry) }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(width: 320, height: 280)
            }
        }
        .padding(16)
        .calculatorGlassPanel()
    }
}

// Sources/IPNetworkCalculator/IPWorkspacePickerView.swift
import SwiftUI
import IPCalculatorFeatures

struct IPWorkspacePickerView: View {
    @Binding var mode: IPWorkspaceMode

    var body: some View {
        Picker("IP 工作区", selection: $mode) {
            ForEach(IPWorkspaceMode.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }
}

// Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift
import SwiftUI
import IPCalculatorFeatures

struct TranslationDirectionPickerView: View {
    @Binding var direction: TranslationDirection

    var body: some View {
        Picker("互转方向", selection: $direction) {
            ForEach(TranslationDirection.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }
}

// Sources/IPNetworkCalculator/IPWorkspaceView.swift
import SwiftUI
import IPCalculatorFeatures

struct IPWorkspaceView: View {
    @Bindable var workbench: CalculatorWorkbenchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            IPWorkspacePickerView(mode: $workbench.navigation.selectedIPMode)
            switch workbench.navigation.selectedIPMode {
            case .network:
                NetworkWorkspaceView(
                    viewModel: workbench.networkWorkspace,
                    onCalculate: workbench.calculateCurrentIPWorkspace
                )
            case .translation:
                TranslationWorkspaceView(
                    viewModel: workbench.translationWorkspace,
                    onCalculate: workbench.calculateCurrentIPWorkspace
                )
            }
            Spacer(minLength: 0)
        }
    }
}

// Sources/IPNetworkCalculator/NetworkWorkspaceView.swift
import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct NetworkWorkspaceView: View {
    @Bindable var viewModel: NetworkWorkspaceViewModel
    let onCalculate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("网段计算").font(.title2.weight(.semibold))
                TextField("192.168.1.10/24 或 10.0.0.7/255.255.255.248", text: $viewModel.networkInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: viewModel.networkInput) { _, newValue in
                        let normalized = InputNormalizer.normalizeFieldText(newValue)
                        if normalized != newValue {
                            viewModel.networkInput = normalized
                        }
                    }
                HStack {
                    Spacer()
                    Button("计算", action: onCalculate)
                        .keyboardShortcut(.return)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .calculatorGlassPanel()

            ResultPanelView(
                statusText: viewModel.statusText,
                errorMessage: viewModel.errorMessage,
                sections: viewModel.resultSections,
                primaryCopyLabel: viewModel.primaryCopyLabel,
                primaryCopyText: viewModel.primaryCopyText,
                copyAllText: viewModel.copyAllText
            )
        }
    }
}

// Sources/IPNetworkCalculator/TranslationWorkspaceView.swift
import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct TranslationWorkspaceView: View {
    @Bindable var viewModel: TranslationWorkspaceViewModel
    let onCalculate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("IPv4 / IPv6 互转").font(.title2.weight(.semibold))
                TranslationDirectionPickerView(direction: $viewModel.direction)
                switch viewModel.direction {
                case .ipv4ToIPv6:
                    TextField("48.235.24.0/30", text: $viewModel.ipv4Input)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: viewModel.ipv4Input) { _, newValue in
                            let normalized = InputNormalizer.normalizeFieldText(newValue)
                            if normalized != newValue {
                                viewModel.ipv4Input = normalized
                            }
                        }
                    TextField("2001:db8::", text: $viewModel.ipv6PrefixInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: viewModel.ipv6PrefixInput) { _, newValue in
                            let normalized = InputNormalizer.normalizeFieldText(newValue)
                            if normalized != newValue {
                                viewModel.ipv6PrefixInput = normalized
                            }
                        }
                case .ipv6ToIPv4:
                    TextField("2001:db8::30eb:1800/126", text: $viewModel.ipv6Input)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: viewModel.ipv6Input) { _, newValue in
                            let normalized = InputNormalizer.normalizeFieldText(newValue)
                            if normalized != newValue {
                                viewModel.ipv6Input = normalized
                            }
                        }
                    TextField("2001:db8::", text: $viewModel.ipv6ReversePrefixInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: viewModel.ipv6ReversePrefixInput) { _, newValue in
                            let normalized = InputNormalizer.normalizeFieldText(newValue)
                            if normalized != newValue {
                                viewModel.ipv6ReversePrefixInput = normalized
                            }
                        }
                }
                HStack {
                    Spacer()
                    Button("计算", action: onCalculate)
                        .keyboardShortcut(.return)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .calculatorGlassPanel()

            ResultPanelView(
                statusText: viewModel.statusText,
                errorMessage: viewModel.errorMessage,
                sections: viewModel.resultSections,
                primaryCopyLabel: viewModel.primaryCopyLabel,
                primaryCopyText: viewModel.primaryCopyText,
                copyAllText: viewModel.copyAllText
            )
        }
    }
}

// Sources/IPNetworkCalculator/ResultPanelView.swift
import SwiftUI
import IPCalculatorFeatures

struct ResultPanelView: View {
    let statusText: String
    let errorMessage: String?
    let sections: [ResultSection]
    let primaryCopyLabel: String
    let primaryCopyText: String
    let copyAllText: String
    @State private var feedback = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(feedback.isEmpty ? statusText : feedback)
                    .font(.headline)
                    .foregroundStyle(errorMessage == nil ? Color.primary : Color.red)
                Spacer()
                if !primaryCopyText.isEmpty {
                    Button("复制 \(primaryCopyLabel)") {
                        ClipboardService.copy(primaryCopyText)
                        flash("已复制：\(primaryCopyLabel)")
                    }
                }
                if !copyAllText.isEmpty {
                    Button("复制全部") {
                        ClipboardService.copy(copyAllText)
                        flash("已复制：全部结果")
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else if sections.isEmpty {
                Text("暂无结果").foregroundStyle(.secondary)
            } else {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title).font(.subheadline.weight(.semibold))
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                            ForEach(section.rows) { row in
                                GridRow {
                                    Text(row.label).foregroundStyle(.secondary)
                                    Button {
                                        ClipboardService.copy(row.value)
                                        flash("已复制：\(row.label)")
                                    } label: {
                                        Text(row.value)
                                            .font(.system(.body, design: .monospaced).bold())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .calculatorGlassPanel()
    }

    private func flash(_ text: String) {
        feedback = text
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            feedback = ""
        }
    }
}

// Sources/IPNetworkCalculator/BaseConversionView.swift
import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct BaseConversionView: View {
    @Bindable var viewModel: BaseConversionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("进制转换").font(.title2.weight(.semibold))
            HStack(spacing: 16) {
                baseField("二进制", text: $viewModel.binaryText, base: .binary)
                baseField("十进制", text: $viewModel.decimalText, base: .decimal)
                baseField("十六进制", text: $viewModel.hexadecimalText, base: .hexadecimal)
            }
            BinaryBitGridView(binary32: viewModel.binary32) { bitIndex in
                viewModel.toggle(bitIndex: bitIndex)
            }
            if let message = viewModel.errorMessage {
                Text(message).foregroundStyle(.red)
            }
        }
        .padding(20)
        .calculatorWorkspaceSurface()
    }

    private func baseField(_ title: String, text: Binding<String>, base: NumberBase) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            TextField(title, text: Binding(
                get: { text.wrappedValue },
                set: { newValue in viewModel.update(text: newValue, base: base) }
            ))
            .font(.system(.body, design: .monospaced))
            .textFieldStyle(.roundedBorder)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(viewModel.invalidBase == base ? Color.red : Color.clear, lineWidth: 1)
            }
        }
    }
}

// Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift
import AppKit
import SwiftUI

final class AppActivationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct IPNetworkCalculatorApp: App {
    @NSApplicationDelegateAdaptor(AppActivationDelegate.self) private var appActivationDelegate

    var body: some Scene {
        WindowGroup("IP 地址计算器") {
            ContentView()
                .frame(minWidth: 980, minHeight: 640)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
```

- [ ] **Step 4: Run the build and tests against the new workbench shell**

Run:

```bash
swift build
swift test
```

Expected: PASS, with `ContentView` now compiling against the new workbench and the feature tests still green.

- [ ] **Step 5: Commit the workbench UI switch**

```bash
git add Sources/IPNetworkCalculator/ContentView.swift Sources/IPNetworkCalculator/SidebarNavigationView.swift Sources/IPNetworkCalculator/HistoryPopoverView.swift Sources/IPNetworkCalculator/IPWorkspaceView.swift Sources/IPNetworkCalculator/IPWorkspacePickerView.swift Sources/IPNetworkCalculator/NetworkWorkspaceView.swift Sources/IPNetworkCalculator/TranslationWorkspaceView.swift Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift Sources/IPNetworkCalculator/ResultPanelView.swift Sources/IPNetworkCalculator/BaseConversionView.swift Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift
git commit -m "feat: switch app to native workbench layout"
```

### Task 5: Polish the Workspaces, Apply Balanced Glass Styling, and Remove Legacy Paths

**Files:**
- Modify: `Sources/IPNetworkCalculator/GlassStyle.swift`
- Modify: `Sources/IPNetworkCalculator/BinaryBitGridView.swift`
- Delete: `Sources/IPCalculatorFeatures/CalculatorViewModel.swift`
- Delete: `Sources/IPCalculatorFeatures/BaseConversionState.swift`
- Delete: `Sources/IPNetworkCalculator/ModePickerView.swift`
- Delete: `Sources/IPNetworkCalculator/InputPanelView.swift`
- Delete: `Sources/IPNetworkCalculator/HistorySidebarView.swift`
- Delete: `Tests/IPCalculatorFeaturesTests/CalculatorViewModelTests.swift`

- [ ] **Step 1: Replace the single legacy glass modifier with workbench-specific surface modifiers, then move the new workbench views onto them**

```swift
// Sources/IPNetworkCalculator/GlassStyle.swift
import SwiftUI

private struct WorkspaceSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .glassEffect()
    }
}

private struct PopoverSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassEffect()
    }
}

extension View {
    func calculatorWorkspaceSurface() -> some View {
        modifier(WorkspaceSurfaceModifier())
    }

    func calculatorPopoverSurface() -> some View {
        modifier(PopoverSurfaceModifier())
    }
}

// Sources/IPNetworkCalculator/BinaryBitGridView.swift
import SwiftUI

struct BinaryBitGridView: View {
    let binary32: String
    let onToggle: (Int) -> Void

    var body: some View {
        let bits = Array(binary32)

        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { byteIndex in
                HStack(spacing: 6) {
                    ForEach(0..<8, id: \.self) { offset in
                        let bitIndex = byteIndex * 8 + offset
                        Button(String(bits[bitIndex])) {
                            onToggle(bitIndex)
                        }
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .frame(width: 28, height: 28)
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}

// Sources/IPNetworkCalculator/HistoryPopoverView.swift
// Replace the last surface modifier with:
.calculatorPopoverSurface()

// Sources/IPNetworkCalculator/NetworkWorkspaceView.swift
// Replace both workbench panel modifiers with:
.calculatorWorkspaceSurface()

// Sources/IPNetworkCalculator/TranslationWorkspaceView.swift
// Replace both workbench panel modifiers with:
.calculatorWorkspaceSurface()

// Sources/IPNetworkCalculator/ResultPanelView.swift
// Replace the last surface modifier with:
.calculatorWorkspaceSurface()

// Sources/IPNetworkCalculator/BaseConversionView.swift
// Replace the last surface modifier with:
.calculatorWorkspaceSurface()
```

- [ ] **Step 2: Run the build to verify the new glass modifiers and bit-grid signature compile cleanly**

Run:

```bash
swift build
```

Expected: PASS.

- [ ] **Step 3: Remove the old monolithic models, shared legacy views, and their obsolete tests**

```text
Delete these files after replacing every reference to them:

- Sources/IPCalculatorFeatures/CalculatorViewModel.swift
- Sources/IPCalculatorFeatures/BaseConversionState.swift
- Sources/IPNetworkCalculator/ModePickerView.swift
- Sources/IPNetworkCalculator/InputPanelView.swift
- Sources/IPNetworkCalculator/HistorySidebarView.swift
- Tests/IPCalculatorFeaturesTests/CalculatorViewModelTests.swift
```

- [ ] **Step 4: Run full verification and launch the app manually**

Run:

```bash
swift test
swift build
swift run IPNetworkCalculator
```

Expected:

- `swift test`: PASS
- `swift build`: PASS
- `swift run IPNetworkCalculator`: the app launches with a sidebar containing `IP 计算` and `进制转换`, `历史` opens from the toolbar, network/translation require `计算`, and base conversion updates without a calculate button

- [ ] **Step 5: Commit the cleanup and polish pass**

```bash
git add Sources/IPNetworkCalculator/GlassStyle.swift Sources/IPNetworkCalculator/BinaryBitGridView.swift Sources/IPCalculatorFeatures/AppNavigationModel.swift Sources/IPCalculatorFeatures/BaseConversionViewModel.swift Sources/IPCalculatorFeatures/CalculatorWorkbenchViewModel.swift Sources/IPCalculatorFeatures/NetworkWorkspaceViewModel.swift Sources/IPCalculatorFeatures/TranslationWorkspaceViewModel.swift Sources/IPNetworkCalculator/ContentView.swift Sources/IPNetworkCalculator/SidebarNavigationView.swift Sources/IPNetworkCalculator/HistoryPopoverView.swift Sources/IPNetworkCalculator/IPWorkspaceView.swift Sources/IPNetworkCalculator/IPWorkspacePickerView.swift Sources/IPNetworkCalculator/NetworkWorkspaceView.swift Sources/IPNetworkCalculator/TranslationWorkspaceView.swift Sources/IPNetworkCalculator/TranslationDirectionPickerView.swift Sources/IPNetworkCalculator/ResultPanelView.swift Sources/IPNetworkCalculator/BaseConversionView.swift Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift Tests/IPCalculatorFeaturesTests/AppNavigationModelTests.swift Tests/IPCalculatorFeaturesTests/HistoryStoreTests.swift Tests/IPCalculatorFeaturesTests/NetworkWorkspaceViewModelTests.swift Tests/IPCalculatorFeaturesTests/TranslationWorkspaceViewModelTests.swift Tests/IPCalculatorFeaturesTests/BaseConversionViewModelTests.swift Tests/IPCalculatorFeaturesTests/CalculatorWorkbenchViewModelTests.swift
git add -u
git commit -m "refactor: remove legacy calculator UI state"
```

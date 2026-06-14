# macOS SwiftUI Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current Tauri/TypeScript IP calculator with a native macOS 26 SwiftUI app that preserves every current feature.

**Architecture:** Build a SwiftUI-first macOS app as a Swift Package that Xcode can open directly. Put IP math and parsing in a pure `IPCalculatorCore` library, UI state and row/clipboard/history mapping in an `IPCalculatorFeatures` library, and the SwiftUI/AppKit app shell in an `IPNetworkCalculator` executable target.

**Tech Stack:** Swift 6.3, Swift Package Manager, SwiftUI, AppKit only for platform services, Swift Testing, macOS 26.5 SDK, `UInt32`, `UInt128`.

---

## File Structure

Create and modify these files:

- Modify: `.gitignore`
  - Keep generated Xcode, SwiftPM, and app build artifacts out of Git.
- Create: `Package.swift`
  - Defines `IPCalculatorCore`, `IPCalculatorFeatures`, and `IPNetworkCalculator` targets plus Swift Testing test targets.
- Create: `Sources/IPCalculatorCore/CoreTypes.swift`
  - Defines shared Core enums needed by early scaffold code.
- Create: `Sources/IPCalculatorCore/InputNormalizer.swift`
  - Full-width and Chinese punctuation normalization.
- Create: `Sources/IPCalculatorCore/IPAddress.swift`
  - `IPVersion`, `ParsedIPAddress`, and formatting helpers.
- Create: `Sources/IPCalculatorCore/AddressCount.swift`
  - Address count formatting through `2^128`, including IPv6 `/0`.
- Create: `Sources/IPCalculatorCore/NetworkCalculator.swift`
  - CIDR/mask parsing, network calculation, IPv4-to-IPv6, IPv6-to-IPv4.
- Create: `Sources/IPCalculatorCore/BaseConversion.swift`
  - 32-bit binary/decimal/hex conversion and bit toggling.
- Create: `Sources/IPCalculatorCore/IPCalculatorError.swift`
  - Domain errors and Chinese user-facing messages.
- Create: `Sources/IPCalculatorFeatures/CalculatorModels.swift`
  - `CalculatorMode`, `ResultRow`, `HistoryEntry`, status types, and copy targets.
- Create: `Sources/IPCalculatorFeatures/HistoryStore.swift`
  - Deduped in-memory max-eight history behavior.
- Create: `Sources/IPCalculatorFeatures/BaseConversionState.swift`
  - UI-facing base conversion state and active-field updates.
- Create: `Sources/IPCalculatorFeatures/CalculatorViewModel.swift`
  - Mode-specific calculation orchestration and ResultRow/copy/history mapping.
- Create: `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`
  - SwiftUI `App` entry.
- Create: `Sources/IPNetworkCalculator/ContentView.swift`
  - Main window layout.
- Create: `Sources/IPNetworkCalculator/ModePickerView.swift`
  - Native segmented mode picker.
- Create: `Sources/IPNetworkCalculator/InputPanelView.swift`
  - Mode-specific inputs.
- Create: `Sources/IPNetworkCalculator/ResultPanelView.swift`
  - Status, result rows, error output, copy buttons.
- Create: `Sources/IPNetworkCalculator/HistorySidebarView.swift`
  - History list.
- Create: `Sources/IPNetworkCalculator/BaseConversionView.swift`
  - Base conversion inputs and bit grid composition.
- Create: `Sources/IPNetworkCalculator/BinaryBitGridView.swift`
  - 32 clickable bit buttons.
- Create: `Sources/IPNetworkCalculator/PlatformServices.swift`
  - `NSPasteboard` clipboard writer and optional window configuration.
- Create: `Sources/IPNetworkCalculator/GlassStyle.swift`
  - Shared SwiftUI Liquid Glass modifiers.
- Create: `Tests/IPCalculatorCoreTests/*.swift`
  - Core behavior tests ported from `src/ipcalc.test.ts`.
- Create: `Tests/IPCalculatorFeaturesTests/*.swift`
  - History, row mapping, and ViewModel behavior tests.
- Modify: `README.md`
  - Update the project description, development commands, and architecture after native app feature parity.
- Modify/Delete after verification: `src/`, `src-tauri/`, `public/`, `index.html`, `package.json`, `package-lock.json`, `tsconfig.json`, `vite.config.ts`, `vitest.config.ts`
  - Remove Tauri/TypeScript only after Swift tests and manual app checks pass.

---

### Task 1: Preserve the Legacy Baseline

**Files:**
- Modify: Git index only

- [ ] **Step 1: Check the current repository state**

Run:

```bash
git status --short
```

Expected: the approved spec and plan are tracked, while legacy files such as `src/`, `src-tauri/`, `package.json`, and `README.md` may still appear as untracked because `.git` was repaired during planning.

- [ ] **Step 2: Add the existing project source baseline**

Run:

```bash
git add .gitignore LICENSE README.md THIRD_PARTY_NOTICES.md index.html package-lock.json package.json public src src-tauri tsconfig.json vite.config.ts vitest.config.ts
```

Expected: all existing legacy project files are staged, but ignored generated files such as `node_modules/`, `dist/`, logs, and `src-tauri/gen/` are not staged.

- [ ] **Step 3: Commit the legacy baseline**

Run:

```bash
git commit -m "chore: track legacy Tauri baseline"
```

Expected: one commit records the current legacy implementation before the Swift migration starts.

---

### Task 2: Add Swift Package Skeleton

**Files:**
- Modify: `.gitignore`
- Create: `Package.swift`
- Create: `Sources/IPCalculatorCore/CoreTypes.swift`
- Create: `Sources/IPCalculatorCore/IPCalculatorError.swift`
- Create: `Sources/IPCalculatorFeatures/CalculatorModels.swift`
- Create: `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`
- Create: `Sources/IPNetworkCalculator/ContentView.swift`
- Create: `Tests/IPCalculatorCoreTests/SmokeTests.swift`
- Create: `Tests/IPCalculatorFeaturesTests/SmokeTests.swift`

- [ ] **Step 1: Extend `.gitignore` for Swift artifacts**

Append these lines to `.gitignore` if absent:

```gitignore

# Swift and Xcode generated output
.build/
DerivedData/
*.xcworkspace/xcuserdata/
*.xcodeproj/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/
*.xcuserstate
```

- [ ] **Step 2: Create `Package.swift`**

Create `Package.swift` with:

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "IPNetworkCalculator",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "IPCalculatorCore", targets: ["IPCalculatorCore"]),
        .library(name: "IPCalculatorFeatures", targets: ["IPCalculatorFeatures"]),
        .executable(name: "IPNetworkCalculator", targets: ["IPNetworkCalculator"])
    ],
    targets: [
        .target(name: "IPCalculatorCore"),
        .target(name: "IPCalculatorFeatures", dependencies: ["IPCalculatorCore"]),
        .executableTarget(
            name: "IPNetworkCalculator",
            dependencies: ["IPCalculatorFeatures", "IPCalculatorCore"]
        ),
        .testTarget(name: "IPCalculatorCoreTests", dependencies: ["IPCalculatorCore"]),
        .testTarget(name: "IPCalculatorFeaturesTests", dependencies: ["IPCalculatorFeatures", "IPCalculatorCore"])
    ]
)
```

- [ ] **Step 3: Create initial Core shared types**

Create `Sources/IPCalculatorCore/CoreTypes.swift` with:

```swift
import Foundation

public enum IPVersion: Int, Sendable {
    case v4 = 4
    case v6 = 6
}

public enum NumberBase: Sendable {
    case binary
    case decimal
    case hexadecimal
}
```

- [ ] **Step 4: Create initial Core error type**

Create `Sources/IPCalculatorCore/IPCalculatorError.swift` with:

```swift
import Foundation

public enum IPCalculatorError: Error, Equatable, Sendable {
    case emptyInput(String)
    case invalidIPAddress(String)
    case invalidIPv4Octet
    case invalidIPv6Hextet
    case invalidPrefixLength(String)
    case prefixLengthOutOfRange(version: IPVersion, value: Int)
    case invalidIPv4Netmask(String)
    case ipv6RequiresNumericPrefix
    case ipv4ToIPv6RequiresIPv4
    case ipv6ToIPv4RequiresIPv6
    case ipv6ReversePrefixTooShort(Int)
    case ipv6PrefixRequired
    case ipv6PrefixMustBe96
    case invalidIPv6Prefix(String)
    case ipv6PrefixHasHostBits
    case ipv6PrefixMismatch
    case invalidBaseDigit(base: NumberBase)
    case unsigned32OutOfRange
    case bitIndexOutOfRange(Int)
}

public extension IPCalculatorError {
    var userMessage: String {
        switch self {
        case .emptyInput(let message):
            message
        case .invalidIPAddress(let text):
            "无效的 IP 地址：\(text)"
        case .invalidIPv4Octet:
            "IPv4 地址段无效"
        case .invalidIPv6Hextet:
            "IPv6 地址段无效"
        case .invalidPrefixLength(let text):
            "无效的前缀长度：\(text)"
        case .prefixLengthOutOfRange(let version, let value):
            "IPv\(version.rawValue) 前缀长度超出范围：\(value)"
        case .invalidIPv4Netmask(let text):
            "无效的 IPv4 子网掩码：\(text)"
        case .ipv6RequiresNumericPrefix:
            "IPv6 需要数字前缀长度"
        case .ipv4ToIPv6RequiresIPv4:
            "V4 -> V6 生成需要 IPv4 地址或网段"
        case .ipv6ToIPv4RequiresIPv6:
            "V6 -> V4 反算需要 IPv6 地址或网段"
        case .ipv6ReversePrefixTooShort:
            "IPv6 网段前缀长度必须在 /96 到 /128 之间"
        case .ipv6PrefixRequired:
            "请输入 IPv6 前 96 位"
        case .ipv6PrefixMustBe96:
            "IPv6 前缀必须是 /96"
        case .invalidIPv6Prefix(let text):
            "无效的 IPv6 前缀：\(text)"
        case .ipv6PrefixHasHostBits:
            "IPv6 /96 前缀的最后 32 位必须为 0"
        case .ipv6PrefixMismatch:
            "IPv6 /96 前缀与 IPv6 地址或网段不匹配"
        case .invalidBaseDigit(let base):
            switch base {
            case .binary:
                "二进制只能包含 0 和 1"
            case .decimal:
                "十进制只能包含 0 到 9"
            case .hexadecimal:
                "十六进制只能包含 0-9 和 A-F"
            }
        case .unsigned32OutOfRange:
            "数值超出 32 位无符号整数范围"
        case .bitIndexOutOfRange(let index):
            "bit index out of range: \(index)"
        }
    }
}
```

- [ ] **Step 5: Create placeholder shared model definitions**

Create `Sources/IPCalculatorFeatures/CalculatorModels.swift` with:

```swift
import Foundation

public enum CalculatorMode: String, CaseIterable, Identifiable, Sendable {
    case network
    case ipv4ToIPv6
    case ipv6ToIPv4
    case baseConversion

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .network:
            "地址/前缀或掩码"
        case .ipv4ToIPv6:
            "V4 -> V6"
        case .ipv6ToIPv4:
            "V6 -> V4"
        case .baseConversion:
            "进制转换"
        }
    }
}

public struct ResultRow: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public var label: String
    public var value: String
    public var isPrimaryCopyTarget: Bool

    public init(label: String, value: String, isPrimaryCopyTarget: Bool = false) {
        self.label = label
        self.value = value
        self.isPrimaryCopyTarget = isPrimaryCopyTarget
    }
}

public struct HistoryEntry: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public var title: String
    public var subtitle: String
    public var copyText: String

    public init(title: String, subtitle: String, copyText: String) {
        self.title = title
        self.subtitle = subtitle
        self.copyText = copyText
    }
}
```

- [ ] **Step 6: Create minimal SwiftUI app entry**

Create `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift` with:

```swift
import SwiftUI

@main
struct IPNetworkCalculatorApp: App {
    var body: some Scene {
        Window("IP 地址计算器", id: "main") {
            ContentView()
                .frame(minWidth: 900, minHeight: 580)
        }
        .windowResizability(.contentMinSize)
    }
}
```

Create `Sources/IPNetworkCalculator/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("IP 地址计算器")
            .font(.title)
            .glassEffect()
            .padding()
    }
}
```

- [ ] **Step 7: Create smoke tests**

Create `Tests/IPCalculatorCoreTests/SmokeTests.swift` with:

```swift
import Testing
@testable import IPCalculatorCore

@Test
func coreTargetLoads() {
    #expect(IPCalculatorError.unsigned32OutOfRange.userMessage == "数值超出 32 位无符号整数范围")
}
```

Create `Tests/IPCalculatorFeaturesTests/SmokeTests.swift` with:

```swift
import Testing
@testable import IPCalculatorFeatures

@Test
func featureTargetLoads() {
    #expect(CalculatorMode.network.title == "地址/前缀或掩码")
}
```

- [ ] **Step 8: Run tests**

Run:

```bash
swift test
```

Expected: both smoke tests pass.

- [ ] **Step 9: Commit**

Run:

```bash
git add .gitignore Package.swift Sources Tests
git commit -m "chore: add Swift package scaffold"
```

---

### Task 3: Implement Input Normalization and Base Conversion

**Files:**
- Create: `Sources/IPCalculatorCore/InputNormalizer.swift`
- Create: `Sources/IPCalculatorCore/BaseConversion.swift`
- Create: `Tests/IPCalculatorCoreTests/InputNormalizerTests.swift`
- Create: `Tests/IPCalculatorCoreTests/BaseConversionTests.swift`

- [ ] **Step 1: Write input normalization tests**

Create `Tests/IPCalculatorCoreTests/InputNormalizerTests.swift` with:

```swift
import Testing
@testable import IPCalculatorCore

@Test
func normalizesFullWidthPunctuationAndWhitespace() {
    #expect(InputNormalizer.normalizeInputText("  １９２．１６８．１．１０／２４ ") == "192.168.1.10/24")
    #expect(InputNormalizer.normalizeInputText("2001：db8：：") == "2001:db8::")
    #expect(InputNormalizer.normalizeInputText("48.235.24.0、30") == "48.235.24.0/30")
}

@Test
func normalizesBaseNumbers() {
    #expect(InputNormalizer.normalizeBaseNumberText(" 0xff_ff ") == "0xffff")
    #expect(InputNormalizer.normalizeBaseNumberText("１，０２４") == "1024")
}
```

- [ ] **Step 2: Write base conversion tests**

Create `Tests/IPCalculatorCoreTests/BaseConversionTests.swift` with:

```swift
import Testing
@testable import IPCalculatorCore

@Test
func convertsBetweenBinaryDecimalAndHexadecimal() throws {
    let decimal = try BaseConverter.convert("255", base: .decimal)
    #expect(decimal.binary == "11111111")
    #expect(decimal.decimal == "255")
    #expect(decimal.hexadecimal == "FF")
    #expect(decimal.binary32 == "00000000000000000000000011111111")

    #expect(try BaseConverter.convert("0b1010", base: .binary).decimal == "10")
    #expect(try BaseConverter.convert("0xff", base: .hexadecimal).binary == "11111111")
}

@Test
func supportsMaximumUnsigned32BitValue() throws {
    let result = try BaseConverter.convert("FFFFFFFF", base: .hexadecimal)
    #expect(result.decimal == "4294967295")
    #expect(result.binary32 == String(repeating: "1", count: 32))
}

@Test
func rejectsValuesOutsideUnsigned32Bits() {
    #expect(throws: IPCalculatorError.unsigned32OutOfRange) {
        _ = try BaseConverter.convert("4294967296", base: .decimal)
    }
    #expect(throws: IPCalculatorError.unsigned32OutOfRange) {
        _ = try BaseConverter.convert(String(repeating: "1", count: 33), base: .binary)
    }
}

@Test
func togglesIndividualBits() throws {
    let highBit = try BaseConverter.toggleBit(value: 0, bitIndex: 31)
    #expect(highBit.hexadecimal == "80000000")
    #expect(highBit.binary32 == "1" + String(repeating: "0", count: 31))

    let cleared = try BaseConverter.toggleBit(value: 8, bitIndex: 3)
    #expect(cleared.decimal == "0")
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
swift test --filter InputNormalizerTests
swift test --filter BaseConversionTests
```

Expected: fail because `InputNormalizer`, `NumberBase`, and `BaseConverter` are not implemented.

- [ ] **Step 4: Implement input normalization**

Create `Sources/IPCalculatorCore/InputNormalizer.swift` with:

```swift
import Foundation

public enum InputNormalizer {
    private static let translation: [Character: Character] = [
        "、": "/",
        "。": ".",
        "．": ".",
        "：": ":",
        "／": "/",
        "，": ","
    ]

    public static func normalizeInputText(_ text: String) -> String {
        let translated = String(text.map { translation[$0] ?? $0 })
        let folded = translated.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? translated
        return folded.filter { !$0.isWhitespace }
    }

    public static func normalizeFieldText(_ text: String) -> String {
        normalizeInputText(text).replacingOccurrences(of: #"/{2,}"#, with: "/", options: .regularExpression)
    }

    public static func normalizeBaseNumberText(_ text: String) -> String {
        normalizeInputText(text)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
}
```

- [ ] **Step 5: Implement base conversion**

Create `Sources/IPCalculatorCore/BaseConversion.swift` with:

```swift
import Foundation

public struct BaseConversionResult: Equatable, Sendable {
    public var value: UInt32
    public var binary: String
    public var decimal: String
    public var hexadecimal: String
    public var binary32: String
}

public enum BaseConverter {
    public static func convert(_ text: String, base: NumberBase) throws -> BaseConversionResult {
        try format(parseUnsigned32(text, base: base))
    }

    public static func format(_ value: UInt32) -> BaseConversionResult {
        BaseConversionResult(
            value: value,
            binary: String(value, radix: 2),
            decimal: String(value),
            hexadecimal: String(value, radix: 16).uppercased(),
            binary32: String(String(value, radix: 2).reversed()).padding(toLength: 32, withPad: "0", startingAt: 0).reversedString
        )
    }

    public static func toggleBit(value: UInt32, bitIndex: Int) throws -> BaseConversionResult {
        guard bitIndex >= 0 && bitIndex < 32 else {
            throw IPCalculatorError.bitIndexOutOfRange(bitIndex)
        }
        return format(value ^ (UInt32(1) << UInt32(bitIndex)))
    }

    private static func parseUnsigned32(_ text: String, base: NumberBase) throws -> UInt32 {
        var digits = InputNormalizer.normalizeBaseNumberText(text)
        if digits.isEmpty { return 0 }

        if base == .binary && digits.lowercased().hasPrefix("0b") {
            digits.removeFirst(2)
        } else if base == .hexadecimal && digits.lowercased().hasPrefix("0x") {
            digits.removeFirst(2)
        }

        if digits.isEmpty { return 0 }

        switch base {
        case .binary:
            guard digits.allSatisfy({ $0 == "0" || $0 == "1" }) else {
                throw IPCalculatorError.invalidBaseDigit(base: .binary)
            }
            return try parseDigits(digits, radix: 2)
        case .decimal:
            guard digits.allSatisfy(\.isNumber) else {
                throw IPCalculatorError.invalidBaseDigit(base: .decimal)
            }
            guard let value = UInt64(digits), value <= UInt64(UInt32.max) else {
                throw IPCalculatorError.unsigned32OutOfRange
            }
            return UInt32(value)
        case .hexadecimal:
            guard digits.allSatisfy({ $0.isHexDigit }) else {
                throw IPCalculatorError.invalidBaseDigit(base: .hexadecimal)
            }
            return try parseDigits(digits, radix: 16)
        }
    }

    private static func parseDigits(_ digits: String, radix: UInt32) throws -> UInt32 {
        var value: UInt64 = 0
        for char in digits.lowercased() {
            guard let digit = UInt32(String(char), radix: Int(radix)) else {
                throw IPCalculatorError.invalidBaseDigit(base: radix == 2 ? .binary : .hexadecimal)
            }
            value = value * UInt64(radix) + UInt64(digit)
            guard value <= UInt64(UInt32.max) else {
                throw IPCalculatorError.unsigned32OutOfRange
            }
        }
        return UInt32(value)
    }
}

private extension Character {
    var isHexDigit: Bool {
        isNumber || ("a"..."f").contains(String(self).lowercased())
    }
}

private extension String {
    var reversedString: String {
        String(reversed())
    }
}
```

- [ ] **Step 6: Run tests**

Run:

```bash
swift test --filter InputNormalizerTests
swift test --filter BaseConversionTests
```

Expected: pass.

- [ ] **Step 7: Commit**

Run:

```bash
git add Sources/IPCalculatorCore/InputNormalizer.swift Sources/IPCalculatorCore/BaseConversion.swift Tests/IPCalculatorCoreTests/InputNormalizerTests.swift Tests/IPCalculatorCoreTests/BaseConversionTests.swift
git commit -m "feat: add input normalization and base conversion"
```

---

### Task 4: Implement IPv4 Parsing and Network Calculation

**Files:**
- Create: `Sources/IPCalculatorCore/IPAddress.swift`
- Create: `Sources/IPCalculatorCore/AddressCount.swift`
- Create: `Sources/IPCalculatorCore/NetworkCalculator.swift`
- Create: `Tests/IPCalculatorCoreTests/IPv4NetworkTests.swift`

- [ ] **Step 1: Write IPv4 network tests**

Create `Tests/IPCalculatorCoreTests/IPv4NetworkTests.swift` with:

```swift
import Testing
@testable import IPCalculatorCore

@Test
func handlesIPv4CIDRInput() throws {
    let result = try NetworkCalculator.calculate("192.168.1.10/24")
    #expect(result.network == "192.168.1.0/24")
    #expect(result.addressCount == "256")
    #expect(result.firstAddress == "192.168.1.0")
    #expect(result.lastAddress == "192.168.1.255")
    #expect(result.classCCount == "1")
}

@Test
func handlesIPv4DottedMaskInput() throws {
    let result = try NetworkCalculator.calculate("10.0.0.7/255.255.255.248")
    #expect(result.network == "10.0.0.0/29")
    #expect(result.addressCount == "8")
    #expect(result.firstAddress == "10.0.0.0")
    #expect(result.lastAddress == "10.0.0.7")
    #expect(result.classCCount == nil)
}

@Test
func handlesIPv4NumericPrefixInput() throws {
    let input = try NetworkCalculator.parseInput(["10.0.0.7", "29"])
    let result = try NetworkCalculator.calculate(input)
    #expect(result.network == "10.0.0.0/29")
    #expect(result.addressCount == "8")
}

@Test
func rejectsInvalidNetmasksAndHostmasks() {
    #expect(throws: IPCalculatorError.invalidIPv4Netmask("255.0.255.0")) {
        _ = try NetworkCalculator.parseInput(["10.0.0.7", "255.0.255.0"])
    }
    #expect(throws: IPCalculatorError.invalidIPv4Netmask("0.0.0.255")) {
        _ = try NetworkCalculator.parseInput(["10.0.0.7", "0.0.0.255"])
    }
    #expect(throws: IPCalculatorError.invalidIPv4Netmask("0.0.0.255")) {
        _ = try NetworkCalculator.parseInput(["10.0.0.7/0.0.0.255"])
    }
}

@Test
func handlesIPv4PrefixBoundaries() throws {
    let zero = try NetworkCalculator.calculate("0.0.0.1/0")
    #expect(zero.network == "0.0.0.0/0")
    #expect(zero.addressCount == "4294967296")
    #expect(zero.firstAddress == "0.0.0.0")
    #expect(zero.lastAddress == "255.255.255.255")

    let host = try NetworkCalculator.calculate("192.168.1.10/32")
    #expect(host.network == "192.168.1.10/32")
    #expect(host.addressCount == "1")
    #expect(host.firstAddress == "192.168.1.10")
    #expect(host.lastAddress == "192.168.1.10")

    let pointToPoint = try NetworkCalculator.calculate("10.0.0.1/31")
    #expect(pointToPoint.network == "10.0.0.0/31")
    #expect(pointToPoint.addressCount == "2")
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter IPv4NetworkTests
```

Expected: fail because IP and network types are missing.

- [ ] **Step 3: Implement IP address types and address counts**

Create `Sources/IPCalculatorCore/IPAddress.swift` with:

```swift
import Foundation

public enum IPVersion: Int, Sendable {
    case v4 = 4
    case v6 = 6
}

public struct ParsedIPAddress: Equatable, Sendable {
    public var version: IPVersion
    public var value: UInt128

    public init(version: IPVersion, value: UInt128) {
        self.version = version
        self.value = value
    }
}

public enum IPAddressFormatter {
    public static func ipv4(_ value: UInt32) -> String {
        [
            String((value >> 24) & 0xff),
            String((value >> 16) & 0xff),
            String((value >> 8) & 0xff),
            String(value & 0xff)
        ].joined(separator: ".")
    }

    public static func ipv6(_ value: UInt128) -> String {
        let groups = (0..<8).map { index in
            UInt16((value >> UInt128((7 - index) * 16)) & 0xffff)
        }
        let run = longestZeroRun(groups)
        var rendered: [String] = []
        var index = 0
        while index < groups.count {
            if run.length >= 2 && index == run.start {
                rendered.append("")
                index += run.length
                if index == groups.count {
                    rendered.append("")
                }
            } else {
                rendered.append(String(groups[index], radix: 16))
                index += 1
            }
        }
        let text = rendered.joined(separator: ":")
        return text.hasPrefix(":") ? ":\(text)" : text
    }

    private static func longestZeroRun(_ groups: [UInt16]) -> (start: Int, length: Int) {
        var best = (-1, 0)
        var current = (-1, 0)
        for (index, group) in groups.enumerated() {
            if group == 0 {
                if current.0 == -1 {
                    current = (index, 0)
                }
                current.1 += 1
                if current.1 > best.1 {
                    best = current
                }
            } else {
                current = (-1, 0)
            }
        }
        return best
    }
}
```

Create `Sources/IPCalculatorCore/AddressCount.swift` with:

```swift
import Foundation

public enum AddressCount: Equatable, Sendable, CustomStringConvertible {
    case value(UInt128)
    case powerOfTwo(exponent: Int)

    public var description: String {
        switch self {
        case .value(let value):
            String(value)
        case .powerOfTwo(let exponent):
            DecimalPowerFormatter.powerOfTwo(exponent)
        }
    }
}

public enum DecimalPowerFormatter {
    public static func powerOfTwo(_ exponent: Int) -> String {
        precondition(exponent >= 0)
        var digits = [1]
        if exponent == 0 { return "1" }
        for _ in 0..<exponent {
            var carry = 0
            for index in digits.indices {
                let doubled = digits[index] * 2 + carry
                digits[index] = doubled % 10
                carry = doubled / 10
            }
            if carry > 0 {
                digits.append(carry)
            }
        }
        return digits.reversed().map(String.init).joined()
    }
}
```

- [ ] **Step 4: Implement IPv4 calculator path**

Create `Sources/IPCalculatorCore/NetworkCalculator.swift` with the IPv4-capable implementation:

```swift
import Foundation

public struct NetworkInput: Equatable, Sendable {
    public var address: ParsedIPAddress
    public var prefixLength: Int
}

public struct NetworkCalculationResult: Equatable, Sendable {
    public var network: String
    public var addressCount: String
    public var firstAddress: String
    public var lastAddress: String
    public var classCCount: String?
}

public enum NetworkCalculator {
    private static let ipv4Bits = 32
    private static let ipv6Bits = 128
    private static let ipv4Size = UInt128(1) << UInt128(32)

    public static func calculate(_ text: String) throws -> NetworkCalculationResult {
        try calculate(parseInput([InputNormalizer.normalizeFieldText(text)]))
    }

    public static func calculate(_ input: NetworkInput) throws -> NetworkCalculationResult {
        switch input.address.version {
        case .v4:
            return calculateIPv4(UInt32(input.address.value), prefixLength: input.prefixLength)
        case .v6:
            return calculateIPv6(input.address.value, prefixLength: input.prefixLength)
        }
    }

    public static func parseInput(_ values: [String]) throws -> NetworkInput {
        let addressText: String
        let prefixText: String

        if values.count == 1 {
            guard let splitIndex = values[0].lastIndex(of: "/") else {
                throw IPCalculatorError.emptyInput("请输入地址和前缀或掩码，例如 10.0.0.1/20")
            }
            addressText = String(values[0][..<splitIndex])
            prefixText = String(values[0][values[0].index(after: splitIndex)...])
        } else if values.count == 2 {
            addressText = values[0]
            prefixText = values[1]
        } else {
            throw IPCalculatorError.emptyInput("请输入地址和前缀或掩码，例如 10.0.0.1/20")
        }

        let address = try parseIPAddress(addressText)
        let prefixLength = try parsePrefix(address: address, prefixText: prefixText)
        return NetworkInput(address: address, prefixLength: prefixLength)
    }

    public static func parseIPAddress(_ text: String) throws -> ParsedIPAddress {
        if text.contains(":") {
            throw IPCalculatorError.invalidIPAddress(text)
        }
        return ParsedIPAddress(version: .v4, value: UInt128(try parseIPv4Address(text)))
    }

    public static func parseIPv4Address(_ text: String) throws -> UInt32 {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else {
            throw IPCalculatorError.invalidIPAddress(text)
        }
        var value: UInt32 = 0
        for part in parts {
            let piece = String(part)
            guard !piece.isEmpty, piece.allSatisfy(\.isNumber), !(piece.count > 1 && piece.hasPrefix("0")) else {
                throw IPCalculatorError.invalidIPv4Octet
            }
            guard let octet = UInt32(piece), octet <= 255 else {
                throw IPCalculatorError.invalidIPv4Octet
            }
            value = (value << 8) | octet
        }
        return value
    }

    private static func parsePrefix(address: ParsedIPAddress, prefixText: String) throws -> Int {
        if address.version == .v4 && prefixText.contains(".") {
            let mask = try parseIPv4Address(prefixText)
            guard let prefix = prefixLengthFromIPv4Netmask(mask),
                  prefixText == IPAddressFormatter.ipv4(ipv4Mask(prefixLength: prefix)) else {
                throw IPCalculatorError.invalidIPv4Netmask(prefixText)
            }
            return prefix
        }
        if address.version == .v6 && prefixText.contains(".") {
            throw IPCalculatorError.ipv6RequiresNumericPrefix
        }
        return try parseNumericPrefix(prefixText, maxPrefix: address.version == .v4 ? 32 : 128, version: address.version)
    }

    private static func parseNumericPrefix(_ text: String, maxPrefix: Int, version: IPVersion) throws -> Int {
        guard let value = Int(text), String(value) == text || text == "+\(value)" else {
            throw IPCalculatorError.invalidPrefixLength(text)
        }
        guard value >= 0 && value <= maxPrefix else {
            throw IPCalculatorError.prefixLengthOutOfRange(version: version, value: value)
        }
        return value
    }

    private static func calculateIPv4(_ address: UInt32, prefixLength: Int) -> NetworkCalculationResult {
        let network = address & ipv4Mask(prefixLength: prefixLength)
        let hostBits = 32 - prefixLength
        let count = AddressCount.value(UInt128(1) << UInt128(hostBits)).description
        let last = network | ~ipv4Mask(prefixLength: prefixLength)
        let classC = (16...24).contains(prefixLength) ? String(UInt64(1) << UInt64(24 - prefixLength)) : nil
        return NetworkCalculationResult(
            network: "\(IPAddressFormatter.ipv4(network))/\(prefixLength)",
            addressCount: count,
            firstAddress: IPAddressFormatter.ipv4(network),
            lastAddress: IPAddressFormatter.ipv4(last),
            classCCount: classC
        )
    }

    private static func calculateIPv6(_ address: UInt128, prefixLength: Int) throws -> NetworkCalculationResult {
        throw IPCalculatorError.invalidIPAddress(IPAddressFormatter.ipv6(address))
    }

    private static func ipv4Mask(prefixLength: Int) -> UInt32 {
        if prefixLength == 0 { return 0 }
        return UInt32.max << UInt32(32 - prefixLength)
    }

    private static func prefixLengthFromIPv4Netmask(_ mask: UInt32) -> Int? {
        var seenZero = false
        var prefixLength = 0
        for bit in stride(from: 31, through: 0, by: -1) {
            let isOne = (mask & (UInt32(1) << UInt32(bit))) != 0
            if isOne && seenZero { return nil }
            if isOne {
                prefixLength += 1
            } else {
                seenZero = true
            }
        }
        return prefixLength
    }
}
```

- [ ] **Step 5: Run IPv4 tests**

Run:

```bash
swift test --filter IPv4NetworkTests
```

Expected: pass.

- [ ] **Step 6: Run all tests**

Run:

```bash
swift test
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

Run:

```bash
git add Sources/IPCalculatorCore/IPAddress.swift Sources/IPCalculatorCore/AddressCount.swift Sources/IPCalculatorCore/NetworkCalculator.swift Tests/IPCalculatorCoreTests/IPv4NetworkTests.swift
git commit -m "feat: add IPv4 network calculation"
```

---

### Task 5: Implement IPv6 Parsing, Formatting, and Large Address Counts

**Files:**
- Modify: `Sources/IPCalculatorCore/NetworkCalculator.swift`
- Create: `Tests/IPCalculatorCoreTests/IPv6NetworkTests.swift`
- Create: `Tests/IPCalculatorCoreTests/AddressCountTests.swift`

- [ ] **Step 1: Write IPv6 and address count tests**

Create `Tests/IPCalculatorCoreTests/IPv6NetworkTests.swift` with:

```swift
import Testing
@testable import IPCalculatorCore

@Test
func handlesIPv6CIDRInput() throws {
    let result = try NetworkCalculator.calculate("2001:db8::1/126")
    #expect(result.network == "2001:db8::/126")
    #expect(result.addressCount == "4")
    #expect(result.firstAddress == "2001:db8::")
    #expect(result.lastAddress == "2001:db8::3")
}

@Test
func handlesIPv6NumericPrefixInput() throws {
    let input = try NetworkCalculator.parseInput(["2001:db8::1", "126"])
    let result = try NetworkCalculator.calculate(input)
    #expect(result.network == "2001:db8::/126")
    #expect(result.addressCount == "4")
}

@Test
func rejectsDottedMasksForIPv6() {
    #expect(throws: IPCalculatorError.ipv6RequiresNumericPrefix) {
        _ = try NetworkCalculator.parseInput(["2001:db8::1", "255.255.255.0"])
    }
}

@Test
func handlesIPv6PrefixBoundaries() throws {
    let host = try NetworkCalculator.calculate("2001:db8::1/128")
    #expect(host.network == "2001:db8::1/128")
    #expect(host.addressCount == "1")
    #expect(host.firstAddress == "2001:db8::1")
    #expect(host.lastAddress == "2001:db8::1")
}
```

Create `Tests/IPCalculatorCoreTests/AddressCountTests.swift` with:

```swift
import Testing
@testable import IPCalculatorCore

@Test
func formatsLargeIPv6AddressCounts() throws {
    let slash64 = try NetworkCalculator.calculate("2001:db8::/64")
    #expect(slash64.addressCount == "18446744073709551616")

    let slash0 = try NetworkCalculator.calculate("::/0")
    #expect(slash0.addressCount == "340282366920938463463374607431768211456")
}

@Test
func formatsPowersOfTwoThrough128() {
    #expect(AddressCount.powerOfTwo(exponent: 0).description == "1")
    #expect(AddressCount.powerOfTwo(exponent: 32).description == "4294967296")
    #expect(AddressCount.powerOfTwo(exponent: 128).description == "340282366920938463463374607431768211456")
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter IPv6NetworkTests
swift test --filter AddressCountTests
```

Expected: fail because IPv6 parsing and calculation are not implemented.

- [ ] **Step 3: Extend `NetworkCalculator` with IPv6 parsing and math**

Modify `NetworkCalculator.parseIPAddress` so it delegates to IPv6 parsing:

```swift
public static func parseIPAddress(_ text: String) throws -> ParsedIPAddress {
    if text.contains(":") {
        return ParsedIPAddress(version: .v6, value: try parseIPv6Address(text))
    }
    return ParsedIPAddress(version: .v4, value: UInt128(try parseIPv4Address(text)))
}
```

Add these functions inside `NetworkCalculator`:

```swift
public static func parseIPv6Address(_ text: String) throws -> UInt128 {
    guard !text.isEmpty, !text.contains(":::") else {
        throw IPCalculatorError.invalidIPAddress(text)
    }

    let parts = text.lowercased().components(separatedBy: "::")
    guard parts.count <= 2 else {
        throw IPCalculatorError.invalidIPAddress(text)
    }

    let head = try parseIPv6Hextets(parts[0])
    let tail = parts.count == 2 ? try parseIPv6Hextets(parts[1]) : []
    let missing = 8 - head.count - tail.count

    if parts.count == 1 && missing != 0 {
        throw IPCalculatorError.invalidIPAddress(text)
    }
    if parts.count == 2 && missing < 1 {
        throw IPCalculatorError.invalidIPAddress(text)
    }

    let groups = head + Array(repeating: UInt16(0), count: missing) + tail
    return groups.reduce(UInt128(0)) { value, group in
        (value << 16) | UInt128(group)
    }
}

private static func parseIPv6Hextets(_ section: String) throws -> [UInt16] {
    if section.isEmpty { return [] }
    return try section.split(separator: ":", omittingEmptySubsequences: false).map { part in
        let text = String(part)
        guard !text.isEmpty, text.count <= 4, let value = UInt16(text, radix: 16) else {
            throw IPCalculatorError.invalidIPv6Hextet
        }
        return value
    }
}

private static func calculateIPv6(_ address: UInt128, prefixLength: Int) throws -> NetworkCalculationResult {
    let network = networkAddress(address, prefixLength: prefixLength, bitLength: 128)
    let hostBits = 128 - prefixLength
    let count = hostBits == 128 ? AddressCount.powerOfTwo(exponent: 128) : AddressCount.value(UInt128(1) << UInt128(hostBits))
    let last = network + (hostBits == 128 ? UInt128.max : (UInt128(1) << UInt128(hostBits)) - 1)
    return NetworkCalculationResult(
        network: "\(IPAddressFormatter.ipv6(network))/\(prefixLength)",
        addressCount: count.description,
        firstAddress: IPAddressFormatter.ipv6(network),
        lastAddress: IPAddressFormatter.ipv6(last),
        classCCount: nil
    )
}

private static func networkAddress(_ address: UInt128, prefixLength: Int, bitLength: Int) -> UInt128 {
    address & networkMask(prefixLength: prefixLength, bitLength: bitLength)
}

private static func networkMask(prefixLength: Int, bitLength: Int) -> UInt128 {
    if prefixLength == 0 { return 0 }
    if prefixLength == bitLength { return UInt128.max }
    let hostBits = bitLength - prefixLength
    return UInt128.max << UInt128(hostBits)
}
```

- [ ] **Step 4: Run IPv6 tests**

Run:

```bash
swift test --filter IPv6NetworkTests
swift test --filter AddressCountTests
```

Expected: pass.

- [ ] **Step 5: Run all tests**

Run:

```bash
swift test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/IPCalculatorCore/NetworkCalculator.swift Tests/IPCalculatorCoreTests/IPv6NetworkTests.swift Tests/IPCalculatorCoreTests/AddressCountTests.swift
git commit -m "feat: add IPv6 network calculation"
```

---

### Task 6: Implement IPv4 and IPv6 Mapping Features

**Files:**
- Modify: `Sources/IPCalculatorCore/NetworkCalculator.swift`
- Create: `Tests/IPCalculatorCoreTests/IPMappingTests.swift`

- [ ] **Step 1: Write mapping tests**

Create `Tests/IPCalculatorCoreTests/IPMappingTests.swift` with:

```swift
import Testing
@testable import IPCalculatorCore

@Test
func generatesIPv6NetworkFromIPv4Network() throws {
    let input = try NetworkCalculator.parseInput(["48.235.24.0/30"])
    let result = try NetworkCalculator.generateIPv6FromIPv4(input, ipv6PrefixText: "2001:db8::")
    #expect(result.ipv4Network == "48.235.24.0/30")
    #expect(result.ipv6Prefix == "2001:db8::/96")
    #expect(result.ipv6Network == "2001:db8::30eb:1800/126")
    #expect(result.addressCount == "4")
    #expect(result.firstAddress == "2001:db8::30eb:1800")
    #expect(result.lastAddress == "2001:db8::30eb:1803")
}

@Test
func reversesIPv6NetworkSuffixesBackToIPv4Networks() throws {
    let result = try NetworkCalculator.generateIPv4FromIPv6("2001:db8::30eb:1800/126", ipv6PrefixText: "2001:db8::")
    #expect(result.ipv6Prefix == "2001:db8::/96")
    #expect(result.ipv6Network == "2001:db8::30eb:1800/126")
    #expect(result.ipv4Network == "48.235.24.0/30")
    #expect(result.addressCount == "4")
    #expect(result.firstAddress == "48.235.24.0")
    #expect(result.lastAddress == "48.235.24.3")
}

@Test
func treatsIPv6AddressesWithoutPrefixAsSingleIPv4Addresses() throws {
    let result = try NetworkCalculator.generateIPv4FromIPv6("2001:db8::30eb:1801")
    #expect(result.ipv6Prefix == "2001:db8::/96")
    #expect(result.ipv6Network == "2001:db8::30eb:1801/128")
    #expect(result.ipv4Network == "48.235.24.1/32")
    #expect(result.addressCount == "1")
}

@Test
func validatesIPv6Prefixes() throws {
    let input = try NetworkCalculator.parseInput(["48.235.24.0/30"])
    #expect(throws: IPCalculatorError.ipv6PrefixHasHostBits) {
        _ = try NetworkCalculator.generateIPv6FromIPv4(input, ipv6PrefixText: "2001:db8::1")
    }
    #expect(throws: IPCalculatorError.ipv6PrefixMismatch) {
        _ = try NetworkCalculator.generateIPv4FromIPv6("2001:db8::30eb:1800/126", ipv6PrefixText: "2001:db9::")
    }
    #expect(throws: IPCalculatorError.ipv6ReversePrefixTooShort(95)) {
        _ = try NetworkCalculator.generateIPv4FromIPv6("2001:db8::/95")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter IPMappingTests
```

Expected: fail because mapping result types and functions are missing.

- [ ] **Step 3: Add mapping result structs and functions**

Add these structs to `NetworkCalculator.swift`:

```swift
public struct IPv4ToIPv6Result: Equatable, Sendable {
    public var ipv4Network: String
    public var ipv6Prefix: String
    public var ipv6Network: String
    public var addressCount: String
    public var firstAddress: String
    public var lastAddress: String
}

public struct IPv6ToIPv4Result: Equatable, Sendable {
    public var ipv6Prefix: String
    public var ipv6Network: String
    public var ipv4Network: String
    public var addressCount: String
    public var firstAddress: String
    public var lastAddress: String
}
```

Add these functions inside `NetworkCalculator`:

```swift
public static func parseIPv6_96Prefix(_ prefixText: String) throws -> UInt128 {
    guard !prefixText.isEmpty else { throw IPCalculatorError.ipv6PrefixRequired }
    if prefixText.contains("/") {
        let input = try parseInput([InputNormalizer.normalizeFieldText(prefixText)])
        guard input.address.version == .v6 else {
            throw IPCalculatorError.invalidIPv6Prefix(prefixText)
        }
        guard input.prefixLength == 96 else {
            throw IPCalculatorError.ipv6PrefixMustBe96
        }
        return networkAddress(input.address.value, prefixLength: 96, bitLength: 128)
    }
    let address: UInt128
    do {
        address = try parseIPv6Address(prefixText)
    } catch {
        throw IPCalculatorError.invalidIPv6Prefix(prefixText)
    }
    let prefixNetwork = networkAddress(address, prefixLength: 96, bitLength: 128)
    guard address == prefixNetwork else {
        throw IPCalculatorError.ipv6PrefixHasHostBits
    }
    return prefixNetwork
}

public static func generateIPv6FromIPv4(_ input: NetworkInput, ipv6PrefixText: String) throws -> IPv4ToIPv6Result {
    guard input.address.version == .v4 else {
        throw IPCalculatorError.ipv4ToIPv6RequiresIPv4
    }
    let ipv4Network = UInt32(input.address.value) & ipv4Mask(prefixLength: input.prefixLength)
    let ipv6Prefix = try parseIPv6_96Prefix(InputNormalizer.normalizeFieldText(ipv6PrefixText))
    let ipv6PrefixLength = 96 + input.prefixLength
    let ipv6Address = ipv6Prefix | UInt128(ipv4Network)
    let ipv6Network = networkAddress(ipv6Address, prefixLength: ipv6PrefixLength, bitLength: 128)
    let hostBits = 128 - ipv6PrefixLength
    let count = AddressCount.value(UInt128(1) << UInt128(hostBits)).description
    return IPv4ToIPv6Result(
        ipv4Network: "\(IPAddressFormatter.ipv4(ipv4Network))/\(input.prefixLength)",
        ipv6Prefix: "\(IPAddressFormatter.ipv6(ipv6Prefix))/96",
        ipv6Network: "\(IPAddressFormatter.ipv6(ipv6Network))/\(ipv6PrefixLength)",
        addressCount: count,
        firstAddress: IPAddressFormatter.ipv6(ipv6Network),
        lastAddress: IPAddressFormatter.ipv6(ipv6Network + (UInt128(1) << UInt128(hostBits)) - 1)
    )
}

public static func generateIPv4FromIPv6(_ ipv6Text: String, ipv6PrefixText: String = "") throws -> IPv6ToIPv4Result {
    let input: NetworkInput
    if ipv6Text.contains("/") {
        input = try parseInput([InputNormalizer.normalizeFieldText(ipv6Text)])
    } else {
        input = NetworkInput(address: ParsedIPAddress(version: .v6, value: try parseIPv6Address(InputNormalizer.normalizeFieldText(ipv6Text))), prefixLength: 128)
    }
    guard input.address.version == .v6 else {
        throw IPCalculatorError.ipv6ToIPv4RequiresIPv6
    }
    guard input.prefixLength >= 96 else {
        throw IPCalculatorError.ipv6ReversePrefixTooShort(input.prefixLength)
    }

    let ipv6Network = networkAddress(input.address.value, prefixLength: input.prefixLength, bitLength: 128)
    let ipv6Prefix = networkAddress(ipv6Network, prefixLength: 96, bitLength: 128)
    if !ipv6PrefixText.isEmpty {
        let expected = try parseIPv6_96Prefix(InputNormalizer.normalizeFieldText(ipv6PrefixText))
        guard expected == ipv6Prefix else {
            throw IPCalculatorError.ipv6PrefixMismatch
        }
    }

    let ipv4PrefixLength = input.prefixLength - 96
    let ipv4Value = UInt32(ipv6Network & (ipv4Size - 1))
    let ipv4Network = ipv4Value & ipv4Mask(prefixLength: ipv4PrefixLength)
    let hostBits = 32 - ipv4PrefixLength
    let count = AddressCount.value(UInt128(1) << UInt128(hostBits)).description
    let last = ipv4Network | ~ipv4Mask(prefixLength: ipv4PrefixLength)
    return IPv6ToIPv4Result(
        ipv6Prefix: "\(IPAddressFormatter.ipv6(ipv6Prefix))/96",
        ipv6Network: "\(IPAddressFormatter.ipv6(ipv6Network))/\(input.prefixLength)",
        ipv4Network: "\(IPAddressFormatter.ipv4(ipv4Network))/\(ipv4PrefixLength)",
        addressCount: count,
        firstAddress: IPAddressFormatter.ipv4(ipv4Network),
        lastAddress: IPAddressFormatter.ipv4(last)
    )
}
```

- [ ] **Step 4: Run mapping tests**

Run:

```bash
swift test --filter IPMappingTests
```

Expected: pass.

- [ ] **Step 5: Run all tests**

Run:

```bash
swift test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/IPCalculatorCore/NetworkCalculator.swift Tests/IPCalculatorCoreTests/IPMappingTests.swift
git commit -m "feat: add IPv4 IPv6 mapping calculations"
```

---

### Task 7: Implement Feature State, History, and ViewModel Mapping

**Files:**
- Modify: `Sources/IPCalculatorFeatures/CalculatorModels.swift`
- Create: `Sources/IPCalculatorFeatures/HistoryStore.swift`
- Create: `Sources/IPCalculatorFeatures/BaseConversionState.swift`
- Create: `Sources/IPCalculatorFeatures/CalculatorViewModel.swift`
- Create: `Tests/IPCalculatorFeaturesTests/HistoryStoreTests.swift`
- Create: `Tests/IPCalculatorFeaturesTests/CalculatorViewModelTests.swift`

- [ ] **Step 1: Write history and ViewModel tests**

Create `Tests/IPCalculatorFeaturesTests/HistoryStoreTests.swift` with:

```swift
import Testing
@testable import IPCalculatorFeatures

@Test
func dedupesAndCapsHistoryAtEight() {
    var store = HistoryStore()
    for index in 1...10 {
        store.add(title: "10.0.\(index).0/24", subtitle: "网段计算 · 10.0.\(index).1/24", copyText: "10.0.\(index).0/24")
    }
    store.add(title: "10.0.10.0/24", subtitle: "网段计算 · 10.0.10.1/24", copyText: "10.0.10.0/24")

    #expect(store.entries.count == 8)
    #expect(store.entries.first?.title == "10.0.10.0/24")
}
```

Create `Tests/IPCalculatorFeaturesTests/CalculatorViewModelTests.swift` with:

```swift
import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func calculatesStandardNetworkRowsAndCopyText() {
    let viewModel = CalculatorViewModel()
    viewModel.networkInput = "192.168.1.10/24"
    viewModel.calculate()

    #expect(viewModel.statusText == "192.168.1.10/24")
    #expect(viewModel.resultRows.map(\.label) == ["网段", "地址数量", "首个地址", "最后地址", "C段数量"])
    #expect(viewModel.resultRows.first?.value == "192.168.1.0/24")
    #expect(viewModel.copyAllText.contains("网段: 192.168.1.0/24"))
    #expect(viewModel.history.entries.first?.title == "192.168.1.0/24")
}

@MainActor
@Test
func calculatesIPv4ToIPv6RowsAndPrimaryCopyText() {
    let viewModel = CalculatorViewModel()
    viewModel.mode = .ipv4ToIPv6
    viewModel.ipv4Input = "48.235.24.0/30"
    viewModel.ipv6PrefixInput = "2001:db8::"
    viewModel.calculate()

    #expect(viewModel.statusText == "IPv6 网段已生成")
    #expect(viewModel.copyNetworkText == "2001:db8::30eb:1800/126")
    #expect(viewModel.copyNetworkLabel == "IPv6 网段")
}

@MainActor
@Test
func calculatesIPv6ToIPv4RowsAndPrimaryCopyText() {
    let viewModel = CalculatorViewModel()
    viewModel.mode = .ipv6ToIPv4
    viewModel.ipv6ReverseInput = "2001:db8::30eb:1800/126"
    viewModel.ipv6ReversePrefixInput = "2001:db8::"
    viewModel.calculate()

    #expect(viewModel.statusText == "IPv4 网段已反算")
    #expect(viewModel.copyNetworkText == "48.235.24.0/30")
    #expect(viewModel.copyNetworkLabel == "IPv4 网段")
}

@MainActor
@Test
func synchronizesBaseConversionState() {
    var state = BaseConversionState()
    state.update(text: "255", base: .decimal)

    #expect(state.binaryText == "11111111")
    #expect(state.decimalText == "255")
    #expect(state.hexadecimalText == "FF")
    #expect(state.binary32.filter { $0 == "1" }.count == 8)

    state.toggle(bitIndex: 31)
    #expect(state.decimalText == "2147483903")
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter HistoryStoreTests
swift test --filter CalculatorViewModelTests
```

Expected: fail because feature state types are missing.

- [ ] **Step 3: Implement history store**

Create `Sources/IPCalculatorFeatures/HistoryStore.swift` with:

```swift
import Foundation

public struct HistoryStore: Equatable, Sendable {
    public private(set) var entries: [HistoryEntry] = []
    public var maxEntries = 8

    public init() {}

    public mutating func add(title: String, subtitle: String, copyText: String) {
        guard !copyText.isEmpty else { return }
        entries.removeAll { $0.copyText == copyText }
        entries.insert(HistoryEntry(title: title, subtitle: subtitle, copyText: copyText), at: 0)
        if entries.count > maxEntries {
            entries.removeSubrange(maxEntries..<entries.count)
        }
    }
}
```

- [ ] **Step 4: Implement base conversion state**

Create `Sources/IPCalculatorFeatures/BaseConversionState.swift` with:

```swift
import Foundation
import IPCalculatorCore

public struct BaseConversionState: Equatable, Sendable {
    public var binaryText = ""
    public var decimalText = ""
    public var hexadecimalText = ""
    public var binary32 = String(repeating: "0", count: 32)
    public var value: UInt32 = 0
    public var hasValue = false
    public var invalidBase: NumberBase?
    public var errorMessage: String?

    public init() {}

    public mutating func update(text: String, base: NumberBase) {
        do {
            if InputNormalizer.normalizeBaseNumberText(text).isEmpty {
                clear()
                return
            }
            let result = try BaseConverter.convert(text, base: base)
            apply(result: result, activeBase: base)
        } catch let error as IPCalculatorError {
            invalidBase = base
            errorMessage = error.userMessage
        } catch {
            invalidBase = base
            errorMessage = String(describing: error)
        }
    }

    public mutating func toggle(bitIndex: Int) {
        do {
            let result = try BaseConverter.toggleBit(value: value, bitIndex: bitIndex)
            apply(result: result, activeBase: nil)
        } catch let error as IPCalculatorError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public mutating func clear() {
        binaryText = ""
        decimalText = ""
        hexadecimalText = ""
        binary32 = String(repeating: "0", count: 32)
        value = 0
        hasValue = false
        invalidBase = nil
        errorMessage = nil
    }

    private mutating func apply(result: BaseConversionResult, activeBase: NumberBase?) {
        value = result.value
        hasValue = true
        if activeBase != .binary { binaryText = result.binary }
        if activeBase != .decimal { decimalText = result.decimal }
        if activeBase != .hexadecimal { hexadecimalText = result.hexadecimal }
        binary32 = result.binary32
        invalidBase = nil
        errorMessage = nil
    }
}
```

- [ ] **Step 5: Implement ViewModel mapping**

Create `Sources/IPCalculatorFeatures/CalculatorViewModel.swift` with:

```swift
import Foundation
import Observation
import IPCalculatorCore

@MainActor
@Observable
public final class CalculatorViewModel {
    public var mode: CalculatorMode = .network
    public var networkInput = ""
    public var ipv4Input = ""
    public var ipv6PrefixInput = ""
    public var ipv6ReverseInput = ""
    public var ipv6ReversePrefixInput = ""
    public var baseState = BaseConversionState()
    public var resultRows: [ResultRow] = []
    public var history = HistoryStore()
    public var statusText = "等待输入..."
    public var errorMessage: String?
    public var copyAllText = ""
    public var copyNetworkText = ""
    public var copyNetworkLabel = "网段"

    public init() {}

    public func calculate() {
        if mode == .baseConversion { return }
        resultRows = []
        errorMessage = nil
        copyAllText = ""
        copyNetworkText = ""
        do {
            switch mode {
            case .network:
                try calculateNetwork()
            case .ipv4ToIPv6:
                try calculateIPv4ToIPv6()
            case .ipv6ToIPv4:
                try calculateIPv6ToIPv4()
            case .baseConversion:
                break
            }
        } catch let error as IPCalculatorError {
            statusText = "错误"
            errorMessage = error.userMessage
        } catch {
            statusText = "错误"
            errorMessage = String(describing: error)
        }
    }

    private func calculateNetwork() throws {
        let raw = InputNormalizer.normalizeFieldText(networkInput)
        guard !raw.isEmpty else {
            throw IPCalculatorError.emptyInput("请输入地址和前缀或掩码，例如 10.0.0.1/20")
        }
        let input = try NetworkCalculator.parseInput([raw])
        let result = try NetworkCalculator.calculate(input)
        let rows = standardRows(result)
        resultRows = rows
        copyAllText = clipboardText(rows)
        statusText = result.network
        history.add(title: result.network, subtitle: "网段计算 · \(result.network)", copyText: result.network)
    }

    private func calculateIPv4ToIPv6() throws {
        let ipv4Raw = InputNormalizer.normalizeFieldText(ipv4Input)
        let prefixRaw = InputNormalizer.normalizeFieldText(ipv6PrefixInput)
        guard !ipv4Raw.isEmpty else { throw IPCalculatorError.emptyInput("请输入 IPv4 网段，例如 48.235.24.0/30") }
        guard !prefixRaw.isEmpty else { throw IPCalculatorError.emptyInput("请输入 IPv6 前 96 位，例如 2001:db8::") }
        let input = try NetworkCalculator.parseInput([ipv4Raw])
        let result = try NetworkCalculator.generateIPv6FromIPv4(input, ipv6PrefixText: prefixRaw)
        let rows = ipv4ToIPv6Rows(result)
        resultRows = rows
        copyAllText = clipboardText(rows)
        copyNetworkText = result.ipv6Network
        copyNetworkLabel = "IPv6 网段"
        statusText = "IPv6 网段已生成"
        history.add(title: result.ipv6Network, subtitle: "V4 -> V6 · \(result.ipv4Network)", copyText: result.ipv6Network)
    }

    private func calculateIPv6ToIPv4() throws {
        let ipv6Raw = InputNormalizer.normalizeFieldText(ipv6ReverseInput)
        let prefixRaw = InputNormalizer.normalizeFieldText(ipv6ReversePrefixInput)
        guard !ipv6Raw.isEmpty else { throw IPCalculatorError.emptyInput("请输入 IPv6 地址或网段，例如 2001:db8::30eb:1800/126") }
        let result = try NetworkCalculator.generateIPv4FromIPv6(ipv6Raw, ipv6PrefixText: prefixRaw)
        let rows = ipv6ToIPv4Rows(result)
        resultRows = rows
        copyAllText = clipboardText(rows)
        copyNetworkText = result.ipv4Network
        copyNetworkLabel = "IPv4 网段"
        statusText = "IPv4 网段已反算"
        history.add(title: result.ipv4Network, subtitle: "V6 -> V4 · \(result.ipv6Network)", copyText: result.ipv4Network)
    }

    private func standardRows(_ result: NetworkCalculationResult) -> [ResultRow] {
        var rows = [
            ResultRow(label: "网段", value: result.network, isPrimaryCopyTarget: true),
            ResultRow(label: "地址数量", value: result.addressCount),
            ResultRow(label: "首个地址", value: result.firstAddress),
            ResultRow(label: "最后地址", value: result.lastAddress)
        ]
        if let classCCount = result.classCCount {
            rows.append(ResultRow(label: "C段数量", value: classCCount))
        }
        return rows
    }

    private func ipv4ToIPv6Rows(_ result: IPv4ToIPv6Result) -> [ResultRow] {
        [
            ResultRow(label: "IPv4 网段", value: result.ipv4Network),
            ResultRow(label: "IPv6 前缀", value: result.ipv6Prefix),
            ResultRow(label: "IPv6 网段", value: result.ipv6Network, isPrimaryCopyTarget: true),
            ResultRow(label: "地址数量", value: result.addressCount),
            ResultRow(label: "首个地址", value: result.firstAddress),
            ResultRow(label: "最后地址", value: result.lastAddress)
        ]
    }

    private func ipv6ToIPv4Rows(_ result: IPv6ToIPv4Result) -> [ResultRow] {
        [
            ResultRow(label: "IPv6 前缀", value: result.ipv6Prefix),
            ResultRow(label: "IPv6 网段", value: result.ipv6Network),
            ResultRow(label: "IPv4 网段", value: result.ipv4Network, isPrimaryCopyTarget: true),
            ResultRow(label: "地址数量", value: result.addressCount),
            ResultRow(label: "首个 IPv4", value: result.firstAddress),
            ResultRow(label: "最后 IPv4", value: result.lastAddress)
        ]
    }

    private func clipboardText(_ rows: [ResultRow]) -> String {
        rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n")
    }
}
```

- [ ] **Step 6: Run feature tests**

Run:

```bash
swift test --filter HistoryStoreTests
swift test --filter CalculatorViewModelTests
```

Expected: pass.

- [ ] **Step 7: Run all tests**

Run:

```bash
swift test
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

Run:

```bash
git add Sources/IPCalculatorFeatures Tests/IPCalculatorFeaturesTests
git commit -m "feat: add calculator view model"
```

---

### Task 8: Build SwiftUI Layout for All Four Modes

**Files:**
- Modify: `Sources/IPNetworkCalculator/ContentView.swift`
- Create: `Sources/IPNetworkCalculator/ModePickerView.swift`
- Create: `Sources/IPNetworkCalculator/InputPanelView.swift`
- Create: `Sources/IPNetworkCalculator/ResultPanelView.swift`
- Create: `Sources/IPNetworkCalculator/HistorySidebarView.swift`
- Create: `Sources/IPNetworkCalculator/BaseConversionView.swift`
- Create: `Sources/IPNetworkCalculator/BinaryBitGridView.swift`

- [ ] **Step 1: Replace `ContentView` with native layout**

Use this structure in `Sources/IPNetworkCalculator/ContentView.swift`:

```swift
import SwiftUI
import IPCalculatorFeatures

struct ContentView: View {
    @State private var viewModel = CalculatorViewModel()

    var body: some View {
        NavigationSplitView {
            HistorySidebarView(history: viewModel.history)
                .navigationTitle("历史记录")
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                header
                ModePickerView(mode: $viewModel.mode)
                if viewModel.mode == .baseConversion {
                    BaseConversionView(state: $viewModel.baseState)
                } else {
                    InputPanelView(viewModel: viewModel)
                    ResultPanelView(viewModel: viewModel)
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle("IP 地址计算器")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("IP 地址计算器")
                .font(.largeTitle.bold())
            Text("IPv4 / IPv6 网段计算、V4 到 V6、V6 到 V4 与 32 位进制转换")
                .foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 2: Add mode picker**

Create `Sources/IPNetworkCalculator/ModePickerView.swift`:

```swift
import SwiftUI
import IPCalculatorFeatures

struct ModePickerView: View {
    @Binding var mode: CalculatorMode

    var body: some View {
        Picker("输入模式", selection: $mode) {
            ForEach(CalculatorMode.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }
}
```

- [ ] **Step 3: Add mode-specific inputs**

Create `Sources/IPNetworkCalculator/InputPanelView.swift`:

```swift
import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct InputPanelView: View {
    @Bindable var viewModel: CalculatorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch viewModel.mode {
            case .network:
                field("地址/前缀或掩码", example: "192.168.1.10/24、10.0.0.7/255.255.255.248 或 2001:db8::1/126", text: $viewModel.networkInput)
            case .ipv4ToIPv6:
                HStack(spacing: 12) {
                    field("IPv4 网段", example: "48.235.24.0/30", text: $viewModel.ipv4Input)
                    field("IPv6 前 96 位", example: "2001:db8::", text: $viewModel.ipv6PrefixInput)
                }
            case .ipv6ToIPv4:
                HStack(spacing: 12) {
                    field("IPv6 地址/网段", example: "2001:db8::30eb:1800/126", text: $viewModel.ipv6ReverseInput)
                    field("IPv6 /96 前缀（可选）", example: "2001:db8::", text: $viewModel.ipv6ReversePrefixInput)
                }
            case .baseConversion:
                EmptyView()
            }

            HStack {
                Spacer()
                Button("计算") {
                    viewModel.calculate()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .glassEffect()
    }

    private func field(_ title: String, example: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(example).font(.caption).foregroundStyle(.secondary)
            TextField(title, text: text)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let normalized = InputNormalizer.normalizeFieldText(newValue)
                    if normalized != newValue {
                        text.wrappedValue = normalized
                    }
                }
        }
    }
}
```

- [ ] **Step 4: Add results and history**

Create `Sources/IPNetworkCalculator/ResultPanelView.swift`:

```swift
import SwiftUI
import IPCalculatorFeatures

struct ResultPanelView: View {
    @Bindable var viewModel: CalculatorViewModel
    @State private var feedback = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(feedback.isEmpty ? viewModel.statusText : feedback)
                    .font(.headline)
                    .foregroundStyle(viewModel.errorMessage == nil ? .primary : .red)
                Spacer()
                if !viewModel.copyNetworkText.isEmpty {
                    Button("复制 \(viewModel.copyNetworkLabel)") {
                        ClipboardService.copy(viewModel.copyNetworkText)
                        flash("已复制：\(viewModel.copyNetworkLabel)")
                    }
                }
                if !viewModel.copyAllText.isEmpty {
                    Button("复制全部") {
                        ClipboardService.copy(viewModel.copyAllText)
                        flash("已复制：全部结果")
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red)
            } else if viewModel.resultRows.isEmpty {
                Text("暂无结果").foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    ForEach(viewModel.resultRows) { row in
                        GridRow {
                            Text(row.label).foregroundStyle(.secondary)
                            Text(row.value)
                                .font(.system(.body, design: .monospaced).bold())
                                .textSelection(.enabled)
                                .onTapGesture {
                                    ClipboardService.copy(row.value)
                                    flash("已复制：\(row.label)")
                                }
                        }
                    }
                }
            }
        }
        .padding()
        .glassEffect()
    }

    private func flash(_ text: String) {
        feedback = text
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            feedback = ""
        }
    }
}
```

Create `Sources/IPNetworkCalculator/HistorySidebarView.swift`:

```swift
import SwiftUI
import IPCalculatorFeatures

struct HistorySidebarView: View {
    var history: HistoryStore

    var body: some View {
        List(history.entries) { entry in
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(.body, design: .monospaced).bold())
                    .textSelection(.enabled)
                Text(entry.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contextMenu {
                Button("复制") {
                    ClipboardService.copy(entry.copyText)
                }
            }
        }
        .overlay {
            if history.entries.isEmpty {
                Text("暂无历史记录").foregroundStyle(.secondary)
            }
        }
    }
}
```

- [ ] **Step 5: Add base conversion UI**

Create `Sources/IPNetworkCalculator/BaseConversionView.swift`:

```swift
import SwiftUI
import IPCalculatorCore
import IPCalculatorFeatures

struct BaseConversionView: View {
    @Binding var state: BaseConversionState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                baseField("二进制", text: $state.binaryText, base: .binary)
                baseField("十进制", text: $state.decimalText, base: .decimal)
                baseField("十六进制", text: $state.hexadecimalText, base: .hexadecimal)
            }
            BinaryBitGridView(binary32: state.binary32) { bitIndex in
                state.toggle(bitIndex: bitIndex)
            }
            if let message = state.errorMessage {
                Text(message).foregroundStyle(.red)
            }
        }
        .padding()
        .glassEffect()
    }

    private func baseField(_ title: String, text: Binding<String>, base: NumberBase) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            TextField(title, text: text)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .onChange(of: text.wrappedValue) { _, newValue in
                    state.update(text: newValue, base: base)
                }
        }
    }
}
```

Create `Sources/IPNetworkCalculator/BinaryBitGridView.swift`:

```swift
import SwiftUI

struct BinaryBitGridView: View {
    var binary32: String
    var onToggle: (Int) -> Void

    private var bits: [Character] {
        Array(binary32)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("32 位二进制").font(.headline)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(0..<2, id: \.self) { row in
                    GridRow {
                        ForEach(0..<16, id: \.self) { column in
                            let position = row * 16 + column
                            let bitIndex = 31 - position
                            Button(String(bits[position])) {
                                onToggle(bitIndex)
                            }
                            .font(.system(.caption, design: .monospaced).bold())
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 6: Add clipboard service**

Create `Sources/IPNetworkCalculator/PlatformServices.swift`:

```swift
import AppKit

enum ClipboardService {
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
```

- [ ] **Step 7: Build app target**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 8: Commit**

Run:

```bash
git add Sources/IPNetworkCalculator
git commit -m "feat: add SwiftUI calculator interface"
```

---

### Task 9: Apply Liquid Glass Polish and Window Details

**Files:**
- Create: `Sources/IPNetworkCalculator/GlassStyle.swift`
- Modify: `Sources/IPNetworkCalculator/ContentView.swift`
- Modify: `Sources/IPNetworkCalculator/InputPanelView.swift`
- Modify: `Sources/IPNetworkCalculator/ResultPanelView.swift`
- Modify: `Sources/IPNetworkCalculator/BaseConversionView.swift`
- Modify: `Sources/IPNetworkCalculator/IPNetworkCalculatorApp.swift`

- [ ] **Step 1: Create shared glass style helpers**

Create `Sources/IPNetworkCalculator/GlassStyle.swift`:

```swift
import SwiftUI

struct GlassPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassEffect()
    }
}

extension View {
    func calculatorGlassPanel() -> some View {
        modifier(GlassPanel())
    }
}
```

- [ ] **Step 2: Replace direct `.glassEffect()` panel usage**

In `InputPanelView`, `ResultPanelView`, and `BaseConversionView`, replace panel-level:

```swift
.glassEffect()
```

with:

```swift
.calculatorGlassPanel()
```

Keep small controls native and do not wrap each row or bit in separate glass effects.

- [ ] **Step 3: Add window sizing and default commands**

Modify `IPNetworkCalculatorApp.swift`:

```swift
import SwiftUI

@main
struct IPNetworkCalculatorApp: App {
    var body: some Scene {
        Window("IP 地址计算器", id: "main") {
            ContentView()
                .frame(minWidth: 900, minHeight: 580)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
```

- [ ] **Step 4: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

Run:

```bash
git add Sources/IPNetworkCalculator
git commit -m "style: apply native Liquid Glass panels"
```

---

### Task 10: Manual Verification on macOS

**Files:**
- No source changes unless defects are found

- [ ] **Step 1: Run all tests**

Run:

```bash
swift test
```

Expected: all tests pass.

- [ ] **Step 2: Launch the app from SwiftPM**

Run:

```bash
swift run IPNetworkCalculator
```

Expected: a native macOS window opens with the SwiftUI calculator UI.

- [ ] **Step 3: Verify network mode manually**

Enter:

```text
192.168.1.10/24
```

Click `计算`.

Expected:

```text
网段: 192.168.1.0/24
地址数量: 256
首个地址: 192.168.1.0
最后地址: 192.168.1.255
C段数量: 1
```

- [ ] **Step 4: Verify IPv4-to-IPv6 mode manually**

Enter:

```text
IPv4 网段: 48.235.24.0/30
IPv6 前 96 位: 2001:db8::
```

Expected primary network:

```text
2001:db8::30eb:1800/126
```

- [ ] **Step 5: Verify IPv6-to-IPv4 mode manually**

Enter:

```text
IPv6 地址/网段: 2001:db8::30eb:1800/126
IPv6 /96 前缀: 2001:db8::
```

Expected primary network:

```text
48.235.24.0/30
```

- [ ] **Step 6: Verify base conversion manually**

Enter decimal:

```text
255
```

Expected:

```text
二进制: 11111111
十六进制: FF
32 位二进制 has eight 1 bits
```

Click bit 31.

Expected decimal:

```text
2147483903
```

- [ ] **Step 7: Verify copy behavior**

Click a result value, `复制全部`, and primary copy button.

Expected: each action writes the correct text to the system clipboard.

- [ ] **Step 8: Commit fixes if manual verification required changes**

If changes were needed:

```bash
git add Sources Tests
git commit -m "fix: address manual verification issues"
```

If no changes were needed, do not create an empty commit.

---

### Task 11: Replace Legacy Project Metadata and Remove Old Stack

**Files:**
- Modify: `README.md`
- Modify: `THIRD_PARTY_NOTICES.md`
- Delete: `src/`
- Delete: `src-tauri/`
- Delete: `public/`
- Delete: `index.html`
- Delete: `package.json`
- Delete: `package-lock.json`
- Delete: `tsconfig.json`
- Delete: `vite.config.ts`
- Delete: `vitest.config.ts`

- [ ] **Step 1: Re-run verification before deletion**

Run:

```bash
swift test
swift build
```

Expected: both pass.

- [ ] **Step 2: Remove legacy Tauri and TypeScript files**

Run:

```bash
git rm -r src src-tauri public
git rm index.html package.json package-lock.json tsconfig.json vite.config.ts vitest.config.ts
```

Expected: old web/Tauri source and config files are staged for deletion.

- [ ] **Step 3: Update `README.md`**

Replace the README with:

```markdown
# IP 地址计算器

一个使用 SwiftUI 为 macOS 26 构建的原生 IP 地址计算工具。

## 功能

- 计算 IPv4 / IPv6 网段、地址数量、首个地址和最后地址
- 支持 CIDR、数字前缀和 IPv4 子网掩码输入
- IPv4 前缀在 `/16` 到 `/24` 时显示 C 段数量
- 根据指定的 IPv6 `/96` 前缀生成对应的 IPv6 网段
- 根据 IPv6 地址或网段的最后 32 位反算 IPv4 地址或网段，可选校验 IPv6 `/96` 前缀
- 支持二进制、十进制、十六进制的 32 位无符号整数转换
- 支持点击 32 位二进制位切换数值
- 点击结果即可复制单项内容
- 支持复制全部结果和历史记录
- 自动处理常见中文输入法标点
- 使用 macOS 原生 SwiftUI 和 Liquid Glass 风格界面

## 技术栈

- Swift 6
- SwiftUI
- AppKit
- Swift Package Manager
- Swift Testing

## 本地开发

请先安装 Xcode 26.5 或更新版本。

运行测试：

```bash
swift test
```

构建：

```bash
swift build
```

运行：

```bash
swift run IPNetworkCalculator
```

也可以在 Xcode 中打开本目录的 Swift Package 后运行 `IPNetworkCalculator` target。

## 项目结构

```text
Sources/IPCalculatorCore/       纯 Swift 计算逻辑
Sources/IPCalculatorFeatures/   SwiftUI 状态、结果行、历史和复制文案映射
Sources/IPNetworkCalculator/    SwiftUI macOS 应用入口和界面
Tests/                          Core 和 Feature 测试
Package.swift                   Swift Package 配置
```

## License

[MIT](LICENSE)
```

- [ ] **Step 4: Update third-party notices**

Modify `THIRD_PARTY_NOTICES.md` to remove Icons8 usage if no icon asset remains. Keep a short note:

```markdown
# Third Party Notices

This native SwiftUI version currently does not bundle third-party visual assets.
```

- [ ] **Step 5: Run verification**

Run:

```bash
swift test
swift build
```

Expected: both pass.

- [ ] **Step 6: Commit cleanup**

Run:

```bash
git add README.md THIRD_PARTY_NOTICES.md Package.swift Sources Tests .gitignore
git commit -m "chore: replace Tauri project with SwiftUI app"
```

---

## Self-Review

Spec coverage:

- All four modes are covered: network, IPv4-to-IPv6, IPv6-to-IPv4, and base conversion.
- Large IPv6 address counts are covered by `AddressCountTests`.
- Core/ViewModel boundaries are enforced by placing result labels and clipboard text in `IPCalculatorFeatures`.
- Liquid Glass is handled by SwiftUI `glassEffect` and shared panel modifiers.
- Tauri/Node/Rust removal is deferred until tests and manual checks pass.

Placeholder scan:

- The plan uses concrete file paths, commands, and code blocks for source-changing tasks.
- Every source-changing task lists concrete files and commands.

Type consistency:

- Core uses `NetworkCalculationResult`, `IPv4ToIPv6Result`, `IPv6ToIPv4Result`, `BaseConversionResult`, and `AddressCount`.
- Feature layer maps Core result structs into `ResultRow`, copy text, and history entries.
- SwiftUI app consumes `CalculatorViewModel`, `HistoryStore`, `BaseConversionState`, and `ResultRow`.

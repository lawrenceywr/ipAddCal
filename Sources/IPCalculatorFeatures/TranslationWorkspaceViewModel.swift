import Foundation
import IPCalculatorCore
import Observation

@MainActor
@Observable
public final class TranslationWorkspaceViewModel {
    public var direction: TranslationDirection = .ipv4ToIPv6 {
        didSet {
            resetResultState()
        }
    }
    public var ipv4Input = ""
    public var ipv6PrefixInput = ""
    public var ipv6Input = ""
    public var ipv6ReversePrefixInput = ""
    public var resultSections: [ResultSection] = []
    public var statusText = "等待输入..."
    public var errorMessage: String?
    public var copyAllText = ""
    public var primaryCopyText = ""
    public var primaryCopyLabel = "IPv6 网段"

    public init() {}

    public func updateIPv4Input(_ text: String) {
        ipv4Input = InputNormalizer.normalizeFieldText(text)
    }

    public func updateIPv6PrefixInput(_ text: String) {
        ipv6PrefixInput = InputNormalizer.normalizeFieldText(text)
    }

    public func updateIPv6Input(_ text: String) {
        ipv6Input = InputNormalizer.normalizeFieldText(text)
    }

    public func updateIPv6ReversePrefixInput(_ text: String) {
        ipv6ReversePrefixInput = InputNormalizer.normalizeFieldText(text)
    }

    @discardableResult
    public func calculate() -> HistoryEntry? {
        resetResultState()

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

    public func restore(
        direction: TranslationDirection,
        ipv4Input: String = "",
        ipv6PrefixInput: String = "",
        ipv6Input: String = "",
        ipv6ReversePrefixInput: String = ""
    ) {
        self.direction = direction
        self.ipv4Input = InputNormalizer.normalizeFieldText(ipv4Input)
        self.ipv6PrefixInput = InputNormalizer.normalizeFieldText(ipv6PrefixInput)
        self.ipv6Input = InputNormalizer.normalizeFieldText(ipv6Input)
        self.ipv6ReversePrefixInput = InputNormalizer.normalizeFieldText(ipv6ReversePrefixInput)
        resetResultState()
    }

    private func calculateIPv4ToIPv6() throws -> HistoryEntry {
        let normalizedIPv4 = InputNormalizer.normalizeFieldText(ipv4Input)
        let normalizedPrefix = InputNormalizer.normalizeFieldText(ipv6PrefixInput)
        guard !normalizedIPv4.isEmpty else {
            throw IPCalculatorError.emptyInput("请输入 IPv4 网段，例如 48.235.24.0/30")
        }
        guard !normalizedPrefix.isEmpty else {
            throw IPCalculatorError.emptyInput("请输入 IPv6 前 96 位，例如 2001:db8::")
        }

        ipv4Input = normalizedIPv4
        ipv6PrefixInput = normalizedPrefix

        let input = try NetworkCalculator.parseInput([normalizedIPv4])
        let result = try NetworkCalculator.generateIPv6FromIPv4(input, ipv6PrefixText: normalizedPrefix)
        let sections = buildIPv4ToIPv6Sections(result)

        resultSections = sections
        statusText = "IPv6 网段已生成"
        copyAllText = clipboardText(sections)
        primaryCopyText = result.ipv6Network
        primaryCopyLabel = "IPv6 网段"

        return HistoryEntry(
            title: result.ipv6Network,
            subtitle: "V4 -> V6 · \(result.ipv4Network)",
            copyText: result.ipv6Network,
            restoreTarget: .ipv4ToIPv6(
                ipv4Input: normalizedIPv4,
                ipv6PrefixInput: normalizedPrefix
            )
        )
    }

    private func calculateIPv6ToIPv4() throws -> HistoryEntry {
        let normalizedIPv6 = InputNormalizer.normalizeFieldText(ipv6Input)
        let normalizedPrefix = InputNormalizer.normalizeFieldText(ipv6ReversePrefixInput)
        guard !normalizedIPv6.isEmpty else {
            throw IPCalculatorError.emptyInput("请输入 IPv6 地址或网段，例如 2001:db8::30eb:1800/126")
        }

        ipv6Input = normalizedIPv6
        ipv6ReversePrefixInput = normalizedPrefix

        let result = try NetworkCalculator.generateIPv4FromIPv6(
            normalizedIPv6,
            ipv6PrefixText: normalizedPrefix
        )
        let sections = buildIPv6ToIPv4Sections(result)

        resultSections = sections
        statusText = "IPv4 网段已反算"
        copyAllText = clipboardText(sections)
        primaryCopyText = result.ipv4Network
        primaryCopyLabel = "IPv4 网段"

        return HistoryEntry(
            title: result.ipv4Network,
            subtitle: "V6 -> V4 · \(result.ipv6Network)",
            copyText: result.ipv4Network,
            restoreTarget: .ipv6ToIPv4(
                ipv6Input: normalizedIPv6,
                ipv6PrefixInput: normalizedPrefix
            )
        )
    }

    private func buildIPv4ToIPv6Sections(_ result: IPv4ToIPv6Result) -> [ResultSection] {
        [
            ResultSection(
                id: "translation.generated",
                title: "生成结果",
                rows: [
                    ResultRow(label: "IPv4 网段", value: result.ipv4Network),
                    ResultRow(label: "IPv6 前缀", value: result.ipv6Prefix),
                    ResultRow(label: "IPv6 网段", value: result.ipv6Network, isPrimaryCopyTarget: true)
                ]
            ),
            ResultSection(
                id: "translation.range",
                title: "地址范围",
                rows: [
                    ResultRow(label: "地址数量", value: result.addressCount),
                    ResultRow(label: "首个地址", value: result.firstAddress),
                    ResultRow(label: "最后地址", value: result.lastAddress)
                ]
            )
        ]
    }

    private func buildIPv6ToIPv4Sections(_ result: IPv6ToIPv4Result) -> [ResultSection] {
        [
            ResultSection(
                id: "translation.generated",
                title: "生成结果",
                rows: [
                    ResultRow(label: "IPv6 前缀", value: result.ipv6Prefix),
                    ResultRow(label: "IPv6 网段", value: result.ipv6Network),
                    ResultRow(label: "IPv4 网段", value: result.ipv4Network, isPrimaryCopyTarget: true)
                ]
            ),
            ResultSection(
                id: "translation.range",
                title: "地址范围",
                rows: [
                    ResultRow(label: "地址数量", value: result.addressCount),
                    ResultRow(label: "首个 IPv4", value: result.firstAddress),
                    ResultRow(label: "最后 IPv4", value: result.lastAddress)
                ]
            )
        ]
    }

    private func clipboardText(_ sections: [ResultSection]) -> String {
        sections
            .flatMap(\.rows)
            .map { "\($0.label): \($0.value)" }
            .joined(separator: "\n")
    }

    private func resetResultState() {
        resultSections = []
        statusText = "等待输入..."
        errorMessage = nil
        copyAllText = ""
        primaryCopyText = ""
        primaryCopyLabel = direction == .ipv4ToIPv6 ? "IPv6 网段" : "IPv4 网段"
    }
}

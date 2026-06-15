import Foundation
import IPCalculatorCore
import Observation

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
        guard mode != .baseConversion else { return }

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
        copyNetworkText = result.network
        copyNetworkLabel = "网段"
        statusText = result.network
        history.add(title: result.network, subtitle: "网段计算 · \(result.network)", copyText: result.network)
    }

    private func calculateIPv4ToIPv6() throws {
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
        guard !ipv6Raw.isEmpty else {
            throw IPCalculatorError.emptyInput("请输入 IPv6 地址或网段，例如 2001:db8::30eb:1800/126")
        }

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

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

    public func updateNetworkInput(_ text: String) {
        networkInput = InputNormalizer.normalizeFieldText(text)
    }

    @discardableResult
    public func calculate() -> HistoryEntry? {
        resetResultState()

        do {
            let normalizedInput = InputNormalizer.normalizeFieldText(networkInput)
            guard !normalizedInput.isEmpty else {
                throw IPCalculatorError.emptyInput("请输入地址和前缀或掩码，例如 10.0.0.1/20")
            }

            networkInput = normalizedInput

            let input = try NetworkCalculator.parseInput([normalizedInput])
            let result = try NetworkCalculator.calculate(input)
            let sections = buildSections(result)

            resultSections = sections
            statusText = result.network
            copyAllText = clipboardText(sections)
            primaryCopyText = result.network

            return HistoryEntry(
                title: result.network,
                subtitle: "网段计算 · \(result.network)",
                copyText: result.network,
                restoreTarget: .network(input: normalizedInput)
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
        networkInput = InputNormalizer.normalizeFieldText(input)
        resetResultState()
    }

    private func buildSections(_ result: NetworkCalculationResult) -> [ResultSection] {
        var sections = [
            ResultSection(
                id: "network.core",
                title: "核心结果",
                rows: [
                    ResultRow(label: "网段", value: result.network, isPrimaryCopyTarget: true),
                    ResultRow(label: "地址数量", value: result.addressCount),
                    ResultRow(label: "首个地址", value: result.firstAddress),
                    ResultRow(label: "最后地址", value: result.lastAddress)
                ]
            )
        ]

        if let classCCount = result.classCCount {
            sections.append(
                ResultSection(
                    id: "network.extended",
                    title: "扩展结果",
                    rows: [ResultRow(label: "C段数量", value: classCCount)]
                )
            )
        }

        return sections
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
        primaryCopyLabel = "网段"
    }
}

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
        navigation.selectedWorkspace.title
    }

    public func calculateCurrentIPWorkspace() {
        guard navigation.selectedWorkspace == .ipCalculation else {
            return
        }

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
        guard let restoreTarget = entry.restoreTarget else {
            return
        }

        navigation.selectedWorkspace = .ipCalculation
        navigation.isHistoryPresented = false

        switch restoreTarget {
        case let .network(input):
            navigation.selectedIPMode = .network
            networkWorkspace.restore(input: input)
        case let .ipv4ToIPv6(ipv4Input, ipv6PrefixInput):
            navigation.selectedIPMode = .translation
            translationWorkspace.restore(
                direction: .ipv4ToIPv6,
                ipv4Input: ipv4Input,
                ipv6PrefixInput: ipv6PrefixInput
            )
        case let .ipv6ToIPv4(ipv6Input, ipv6PrefixInput):
            navigation.selectedIPMode = .translation
            translationWorkspace.restore(
                direction: .ipv6ToIPv4,
                ipv6Input: ipv6Input,
                ipv6ReversePrefixInput: ipv6PrefixInput
            )
        }
    }
}

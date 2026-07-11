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

public enum TranslationInputField: Sendable {
    case ipv4Input
    case ipv6PrefixInput
    case ipv6Input
    case ipv6ReversePrefixInput
}

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

public struct ResultSection: Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var rows: [ResultRow]

    public init(id: String, title: String, rows: [ResultRow]) {
        self.id = id
        self.title = title
        self.rows = rows
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

    public static func == (lhs: ResultRow, rhs: ResultRow) -> Bool {
        lhs.label == rhs.label
            && lhs.value == rhs.value
            && lhs.isPrimaryCopyTarget == rhs.isPrimaryCopyTarget
    }
}

public enum HistoryRestoreTarget: Equatable, Sendable {
    case network(input: String)
    case ipv4ToIPv6(ipv4Input: String, ipv6PrefixInput: String)
    case ipv6ToIPv4(ipv6Input: String, ipv6PrefixInput: String)
}

public struct HistoryEntry: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public var title: String
    public var subtitle: String
    public var copyText: String
    public var restoreTarget: HistoryRestoreTarget?

    public init(
        title: String,
        subtitle: String,
        copyText: String,
        restoreTarget: HistoryRestoreTarget? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.copyText = copyText
        self.restoreTarget = restoreTarget
    }
}

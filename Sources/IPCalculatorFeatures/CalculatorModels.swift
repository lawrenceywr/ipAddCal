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

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

import Foundation

public struct NetworkInput: Equatable, Sendable {
    public var address: ParsedIPAddress
    public var prefixLength: Int

    public init(address: ParsedIPAddress, prefixLength: Int) {
        self.address = address
        self.prefixLength = prefixLength
    }
}

public struct NetworkCalculationResult: Equatable, Sendable {
    public var network: String
    public var addressCount: String
    public var firstAddress: String
    public var lastAddress: String
    public var classCCount: String?

    public init(
        network: String,
        addressCount: String,
        firstAddress: String,
        lastAddress: String,
        classCCount: String? = nil
    ) {
        self.network = network
        self.addressCount = addressCount
        self.firstAddress = firstAddress
        self.lastAddress = lastAddress
        self.classCCount = classCCount
    }
}

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

public enum NetworkCalculator {
    private static let ipv4Size = UInt128(1) << UInt128(32)

    public static func calculate(_ text: String) throws -> NetworkCalculationResult {
        try calculate(parseInput([InputNormalizer.normalizeFieldText(text)]))
    }

    public static func calculate(_ input: NetworkInput) throws -> NetworkCalculationResult {
        switch input.address.version {
        case .v4:
            return calculateIPv4(UInt32(input.address.value), prefixLength: input.prefixLength)
        case .v6:
            return try calculateIPv6(input.address.value, prefixLength: input.prefixLength)
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
            return ParsedIPAddress(version: .v6, value: try parseIPv6Address(text))
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
            guard !piece.isEmpty,
                  piece.allSatisfy(\.isNumber),
                  !(piece.count > 1 && piece.hasPrefix("0"))
            else {
                throw IPCalculatorError.invalidIPv4Octet
            }
            guard let octet = UInt32(piece), octet <= 255 else {
                throw IPCalculatorError.invalidIPv4Octet
            }
            value = (value << 8) | octet
        }
        return value
    }

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

    public static func parseIPv6_96Prefix(_ prefixText: String) throws -> UInt128 {
        guard !prefixText.isEmpty else {
            throw IPCalculatorError.ipv6PrefixRequired
        }

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

    public static func generateIPv6FromIPv4(
        _ input: NetworkInput,
        ipv6PrefixText: String
    ) throws -> IPv4ToIPv6Result {
        guard input.address.version == .v4 else {
            throw IPCalculatorError.ipv4ToIPv6RequiresIPv4
        }

        let ipv4Network = UInt32(input.address.value) & ipv4Mask(prefixLength: input.prefixLength)
        let ipv6Prefix = try parseIPv6_96Prefix(InputNormalizer.normalizeFieldText(ipv6PrefixText))
        let ipv6PrefixLength = 96 + input.prefixLength
        let ipv6Address = ipv6Prefix | UInt128(ipv4Network)
        let ipv6Network = networkAddress(ipv6Address, prefixLength: ipv6PrefixLength, bitLength: 128)
        let hostBits = 128 - ipv6PrefixLength
        let addressCount = AddressCount.value(UInt128(1) << UInt128(hostBits)).description
        let lastAddress = ipv6Network + (UInt128(1) << UInt128(hostBits)) - 1

        return IPv4ToIPv6Result(
            ipv4Network: "\(IPAddressFormatter.ipv4(ipv4Network))/\(input.prefixLength)",
            ipv6Prefix: "\(IPAddressFormatter.ipv6(ipv6Prefix))/96",
            ipv6Network: "\(IPAddressFormatter.ipv6(ipv6Network))/\(ipv6PrefixLength)",
            addressCount: addressCount,
            firstAddress: IPAddressFormatter.ipv6(ipv6Network),
            lastAddress: IPAddressFormatter.ipv6(lastAddress)
        )
    }

    public static func generateIPv4FromIPv6(
        _ ipv6Text: String,
        ipv6PrefixText: String = ""
    ) throws -> IPv6ToIPv4Result {
        let normalizedIPv6Text = InputNormalizer.normalizeFieldText(ipv6Text)
        let input: NetworkInput
        if normalizedIPv6Text.contains("/") {
            input = try parseInput([normalizedIPv6Text])
        } else {
            input = NetworkInput(
                address: ParsedIPAddress(version: .v6, value: try parseIPv6Address(normalizedIPv6Text)),
                prefixLength: 128
            )
        }

        guard input.address.version == .v6 else {
            throw IPCalculatorError.ipv6ToIPv4RequiresIPv6
        }
        guard input.prefixLength >= 96 else {
            throw IPCalculatorError.ipv6ReversePrefixTooShort(input.prefixLength)
        }

        let ipv6Network = networkAddress(input.address.value, prefixLength: input.prefixLength, bitLength: 128)
        let ipv6Prefix = networkAddress(ipv6Network, prefixLength: 96, bitLength: 128)
        let normalizedPrefixText = InputNormalizer.normalizeFieldText(ipv6PrefixText)
        if !normalizedPrefixText.isEmpty {
            let expectedPrefix = try parseIPv6_96Prefix(normalizedPrefixText)
            guard expectedPrefix == ipv6Prefix else {
                throw IPCalculatorError.ipv6PrefixMismatch
            }
        }

        let ipv4PrefixLength = input.prefixLength - 96
        let ipv4Value = UInt32(ipv6Network & (ipv4Size - 1))
        let ipv4Network = ipv4Value & ipv4Mask(prefixLength: ipv4PrefixLength)
        let hostBits = 32 - ipv4PrefixLength
        let addressCount = AddressCount.value(UInt128(1) << UInt128(hostBits)).description
        let lastAddress = ipv4Network | ~ipv4Mask(prefixLength: ipv4PrefixLength)

        return IPv6ToIPv4Result(
            ipv6Prefix: "\(IPAddressFormatter.ipv6(ipv6Prefix))/96",
            ipv6Network: "\(IPAddressFormatter.ipv6(ipv6Network))/\(input.prefixLength)",
            ipv4Network: "\(IPAddressFormatter.ipv4(ipv4Network))/\(ipv4PrefixLength)",
            addressCount: addressCount,
            firstAddress: IPAddressFormatter.ipv4(ipv4Network),
            lastAddress: IPAddressFormatter.ipv4(lastAddress)
        )
    }

    private static func parsePrefix(address: ParsedIPAddress, prefixText: String) throws -> Int {
        if address.version == .v4 && prefixText.contains(".") {
            let mask = try parseIPv4Address(prefixText)
            guard let prefixLength = prefixLengthFromIPv4Netmask(mask),
                  prefixText == IPAddressFormatter.ipv4(ipv4Mask(prefixLength: prefixLength))
            else {
                throw IPCalculatorError.invalidIPv4Netmask(prefixText)
            }
            return prefixLength
        }

        if address.version == .v6 && prefixText.contains(".") {
            throw IPCalculatorError.ipv6RequiresNumericPrefix
        }

        return try parseNumericPrefix(
            prefixText,
            maxPrefix: address.version == .v4 ? 32 : 128,
            version: address.version
        )
    }

    private static func parseNumericPrefix(_ text: String, maxPrefix: Int, version: IPVersion) throws -> Int {
        guard text.range(of: #"^[+-]?\d+$"#, options: .regularExpression) != nil,
              let value = Int(text)
        else {
            throw IPCalculatorError.invalidPrefixLength(text)
        }

        guard value >= 0 && value <= maxPrefix else {
            throw IPCalculatorError.prefixLengthOutOfRange(version: version, value: value)
        }
        return value
    }

    private static func calculateIPv4(_ address: UInt32, prefixLength: Int) -> NetworkCalculationResult {
        let mask = ipv4Mask(prefixLength: prefixLength)
        let network = address & mask
        let hostBits = 32 - prefixLength
        let addressCount = AddressCount.value(UInt128(1) << UInt128(hostBits)).description
        let lastAddress = network | ~mask
        let classCCount = (16...24).contains(prefixLength)
            ? String(UInt64(1) << UInt64(24 - prefixLength))
            : nil

        return NetworkCalculationResult(
            network: "\(IPAddressFormatter.ipv4(network))/\(prefixLength)",
            addressCount: addressCount,
            firstAddress: IPAddressFormatter.ipv4(network),
            lastAddress: IPAddressFormatter.ipv4(lastAddress),
            classCCount: classCCount
        )
    }

    private static func calculateIPv6(_ address: UInt128, prefixLength: Int) throws -> NetworkCalculationResult {
        let network = networkAddress(address, prefixLength: prefixLength, bitLength: 128)
        let hostBits = 128 - prefixLength
        let count = hostBits == 128
            ? AddressCount.powerOfTwo(exponent: 128)
            : AddressCount.value(UInt128(1) << UInt128(hostBits))
        let lastAddress = hostBits == 128
            ? UInt128.max
            : network + (UInt128(1) << UInt128(hostBits)) - 1

        return NetworkCalculationResult(
            network: "\(IPAddressFormatter.ipv6(network))/\(prefixLength)",
            addressCount: count.description,
            firstAddress: IPAddressFormatter.ipv6(network),
            lastAddress: IPAddressFormatter.ipv6(lastAddress)
        )
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
            if isOne && seenZero {
                return nil
            }
            if isOne {
                prefixLength += 1
            } else {
                seenZero = true
            }
        }

        return prefixLength
    }

    private static func parseIPv6Hextets(_ section: String) throws -> [UInt16] {
        if section.isEmpty { return [] }

        return try section.split(separator: ":", omittingEmptySubsequences: false).map { part in
            let text = String(part)
            guard !text.isEmpty,
                  text.count <= 4,
                  let value = UInt16(text, radix: 16)
            else {
                throw IPCalculatorError.invalidIPv6Hextet
            }
            return value
        }
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
}

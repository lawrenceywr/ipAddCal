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

public enum NetworkCalculator {
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
}

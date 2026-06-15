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
        let binary = String(value, radix: 2)
        return BaseConversionResult(
            value: value,
            binary: binary,
            decimal: String(value),
            hexadecimal: String(value, radix: 16).uppercased(),
            binary32: String(repeating: "0", count: max(0, 32 - binary.count)) + binary
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
        isNumber || "abcdef".contains(String(self).lowercased())
    }
}

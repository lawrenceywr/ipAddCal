import Foundation

public enum AddressCount: Equatable, Sendable, CustomStringConvertible {
    case value(UInt128)
    case powerOfTwo(exponent: Int)

    public var description: String {
        switch self {
        case .value(let value):
            String(value)
        case .powerOfTwo(let exponent):
            DecimalPowerFormatter.powerOfTwo(exponent)
        }
    }
}

public enum DecimalPowerFormatter {
    public static func powerOfTwo(_ exponent: Int) -> String {
        precondition(exponent >= 0)
        if exponent == 0 { return "1" }

        var digits = [1]
        for _ in 0..<exponent {
            var carry = 0
            for index in digits.indices {
                let doubled = digits[index] * 2 + carry
                digits[index] = doubled % 10
                carry = doubled / 10
            }
            if carry > 0 {
                digits.append(carry)
            }
        }

        return digits.reversed().map(String.init).joined()
    }
}

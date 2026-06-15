import Foundation
import IPCalculatorCore

public struct BaseConversionState: Equatable, Sendable {
    public var binaryText = ""
    public var decimalText = ""
    public var hexadecimalText = ""
    public var binary32 = String(repeating: "0", count: 32)
    public var value: UInt32 = 0
    public var hasValue = false
    public var invalidBase: NumberBase?
    public var errorMessage: String?

    public init() {}

    public mutating func update(text: String, base: NumberBase) {
        let normalizedText = InputNormalizer.normalizeBaseNumberText(text)
        setText(normalizedText, for: base)

        do {
            if normalizedText.isEmpty {
                clear()
                return
            }

            let result = try BaseConverter.convert(normalizedText, base: base)
            apply(result: result, activeBase: base, activeText: normalizedText)
        } catch let error as IPCalculatorError {
            invalidBase = base
            errorMessage = error.userMessage
        } catch {
            invalidBase = base
            errorMessage = String(describing: error)
        }
    }

    public mutating func toggle(bitIndex: Int) {
        do {
            let result = try BaseConverter.toggleBit(value: value, bitIndex: bitIndex)
            apply(result: result, activeBase: nil, activeText: nil)
        } catch let error as IPCalculatorError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public mutating func clear() {
        binaryText = ""
        decimalText = ""
        hexadecimalText = ""
        binary32 = String(repeating: "0", count: 32)
        value = 0
        hasValue = false
        invalidBase = nil
        errorMessage = nil
    }

    private mutating func setText(_ text: String, for base: NumberBase) {
        switch base {
        case .binary:
            binaryText = text
        case .decimal:
            decimalText = text
        case .hexadecimal:
            hexadecimalText = text
        }
    }

    private mutating func apply(result: BaseConversionResult, activeBase: NumberBase?, activeText: String?) {
        value = result.value
        hasValue = true
        binaryText = activeBase == .binary ? activeText ?? result.binary : result.binary
        decimalText = activeBase == .decimal ? activeText ?? result.decimal : result.decimal
        hexadecimalText = activeBase == .hexadecimal ? activeText ?? result.hexadecimal : result.hexadecimal
        binary32 = result.binary32
        invalidBase = nil
        errorMessage = nil
    }
}

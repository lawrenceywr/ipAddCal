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
        do {
            if InputNormalizer.normalizeBaseNumberText(text).isEmpty {
                clear()
                return
            }

            let result = try BaseConverter.convert(text, base: base)
            apply(result: result)
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
            apply(result: result)
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

    private mutating func apply(result: BaseConversionResult) {
        value = result.value
        hasValue = true
        binaryText = result.binary
        decimalText = result.decimal
        hexadecimalText = result.hexadecimal
        binary32 = result.binary32
        invalidBase = nil
        errorMessage = nil
    }
}

import Testing
@testable import IPCalculatorCore

@Test
func convertsBetweenBinaryDecimalAndHexadecimal() throws {
    let decimal = try BaseConverter.convert("255", base: .decimal)
    #expect(decimal.binary == "11111111")
    #expect(decimal.decimal == "255")
    #expect(decimal.hexadecimal == "FF")
    #expect(decimal.binary32 == "00000000000000000000000011111111")

    #expect(try BaseConverter.convert("0b1010", base: .binary).decimal == "10")
    #expect(try BaseConverter.convert("0xff", base: .hexadecimal).binary == "11111111")
}

@Test
func supportsMaximumUnsigned32BitValue() throws {
    let result = try BaseConverter.convert("FFFFFFFF", base: .hexadecimal)
    #expect(result.decimal == "4294967295")
    #expect(result.binary32 == String(repeating: "1", count: 32))
}

@Test
func rejectsValuesOutsideUnsigned32Bits() {
    #expect(throws: IPCalculatorError.unsigned32OutOfRange) {
        _ = try BaseConverter.convert("4294967296", base: .decimal)
    }
    #expect(throws: IPCalculatorError.unsigned32OutOfRange) {
        _ = try BaseConverter.convert(String(repeating: "1", count: 33), base: .binary)
    }
}

@Test
func togglesIndividualBits() throws {
    let highBit = try BaseConverter.toggleBit(value: 0, bitIndex: 31)
    #expect(highBit.hexadecimal == "80000000")
    #expect(highBit.binary32 == "1" + String(repeating: "0", count: 31))

    let cleared = try BaseConverter.toggleBit(value: 8, bitIndex: 3)
    #expect(cleared.decimal == "0")
}

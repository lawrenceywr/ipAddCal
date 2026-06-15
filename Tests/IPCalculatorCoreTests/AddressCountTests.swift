import Testing
@testable import IPCalculatorCore

@Test
func formatsLargeIPv6AddressCounts() throws {
    let slash64 = try NetworkCalculator.calculate("2001:db8::/64")
    #expect(slash64.addressCount == "18446744073709551616")

    let slash0 = try NetworkCalculator.calculate("::/0")
    #expect(slash0.addressCount == "340282366920938463463374607431768211456")
}

@Test
func formatsPowersOfTwoThrough128() {
    #expect(AddressCount.powerOfTwo(exponent: 0).description == "1")
    #expect(AddressCount.powerOfTwo(exponent: 32).description == "4294967296")
    #expect(AddressCount.powerOfTwo(exponent: 128).description == "340282366920938463463374607431768211456")
}

import Testing
@testable import IPCalculatorCore

@Test
func handlesIPv6CIDRInput() throws {
    let result = try NetworkCalculator.calculate("2001:db8::1/126")
    #expect(result.network == "2001:db8::/126")
    #expect(result.addressCount == "4")
    #expect(result.firstAddress == "2001:db8::")
    #expect(result.lastAddress == "2001:db8::3")
}

@Test
func handlesIPv6NumericPrefixInput() throws {
    let input = try NetworkCalculator.parseInput(["2001:db8::1", "126"])
    let result = try NetworkCalculator.calculate(input)
    #expect(result.network == "2001:db8::/126")
    #expect(result.addressCount == "4")
}

@Test
func rejectsDottedMasksForIPv6() {
    #expect(throws: IPCalculatorError.ipv6RequiresNumericPrefix) {
        _ = try NetworkCalculator.parseInput(["2001:db8::1", "255.255.255.0"])
    }
}

@Test
func handlesIPv6PrefixBoundaries() throws {
    let host = try NetworkCalculator.calculate("2001:db8::1/128")
    #expect(host.network == "2001:db8::1/128")
    #expect(host.addressCount == "1")
    #expect(host.firstAddress == "2001:db8::1")
    #expect(host.lastAddress == "2001:db8::1")
}

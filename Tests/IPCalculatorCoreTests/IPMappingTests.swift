import Testing
@testable import IPCalculatorCore

@Test
func generatesIPv6NetworkFromIPv4Network() throws {
    let input = try NetworkCalculator.parseInput(["48.235.24.0/30"])
    let result = try NetworkCalculator.generateIPv6FromIPv4(input, ipv6PrefixText: "2001:db8::")
    #expect(result.ipv4Network == "48.235.24.0/30")
    #expect(result.ipv6Prefix == "2001:db8::/96")
    #expect(result.ipv6Network == "2001:db8::30eb:1800/126")
    #expect(result.addressCount == "4")
    #expect(result.firstAddress == "2001:db8::30eb:1800")
    #expect(result.lastAddress == "2001:db8::30eb:1803")
}

@Test
func reversesIPv6NetworkSuffixesBackToIPv4Networks() throws {
    let result = try NetworkCalculator.generateIPv4FromIPv6(
        "2001:db8::30eb:1800/126",
        ipv6PrefixText: "2001:db8::"
    )
    #expect(result.ipv6Prefix == "2001:db8::/96")
    #expect(result.ipv6Network == "2001:db8::30eb:1800/126")
    #expect(result.ipv4Network == "48.235.24.0/30")
    #expect(result.addressCount == "4")
    #expect(result.firstAddress == "48.235.24.0")
    #expect(result.lastAddress == "48.235.24.3")
}

@Test
func treatsIPv6AddressesWithoutPrefixAsSingleIPv4Addresses() throws {
    let result = try NetworkCalculator.generateIPv4FromIPv6("2001:db8::30eb:1801")
    #expect(result.ipv6Prefix == "2001:db8::/96")
    #expect(result.ipv6Network == "2001:db8::30eb:1801/128")
    #expect(result.ipv4Network == "48.235.24.1/32")
    #expect(result.addressCount == "1")
}

@Test
func validatesIPv6Prefixes() throws {
    let input = try NetworkCalculator.parseInput(["48.235.24.0/30"])
    #expect(throws: IPCalculatorError.ipv6PrefixHasHostBits) {
        _ = try NetworkCalculator.generateIPv6FromIPv4(input, ipv6PrefixText: "2001:db8::1")
    }
    #expect(throws: IPCalculatorError.ipv6PrefixMismatch) {
        _ = try NetworkCalculator.generateIPv4FromIPv6(
            "2001:db8::30eb:1800/126",
            ipv6PrefixText: "2001:db9::"
        )
    }
    #expect(throws: IPCalculatorError.ipv6ReversePrefixTooShort(95)) {
        _ = try NetworkCalculator.generateIPv4FromIPv6("2001:db8::/95")
    }
}

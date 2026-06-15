import Testing
@testable import IPCalculatorCore

@Test
func handlesIPv4CIDRInput() throws {
    let result = try NetworkCalculator.calculate("192.168.1.10/24")
    #expect(result.network == "192.168.1.0/24")
    #expect(result.addressCount == "256")
    #expect(result.firstAddress == "192.168.1.0")
    #expect(result.lastAddress == "192.168.1.255")
    #expect(result.classCCount == "1")
}

@Test
func handlesIPv4DottedMaskInput() throws {
    let result = try NetworkCalculator.calculate("10.0.0.7/255.255.255.248")
    #expect(result.network == "10.0.0.0/29")
    #expect(result.addressCount == "8")
    #expect(result.firstAddress == "10.0.0.0")
    #expect(result.lastAddress == "10.0.0.7")
    #expect(result.classCCount == nil)
}

@Test
func handlesIPv4NumericPrefixInput() throws {
    let input = try NetworkCalculator.parseInput(["10.0.0.7", "29"])
    let result = try NetworkCalculator.calculate(input)
    #expect(result.network == "10.0.0.0/29")
    #expect(result.addressCount == "8")
}

@Test
func rejectsInvalidNetmasksAndHostmasks() {
    #expect(throws: IPCalculatorError.invalidIPv4Netmask("255.0.255.0")) {
        _ = try NetworkCalculator.parseInput(["10.0.0.7", "255.0.255.0"])
    }
    #expect(throws: IPCalculatorError.invalidIPv4Netmask("0.0.0.255")) {
        _ = try NetworkCalculator.parseInput(["10.0.0.7", "0.0.0.255"])
    }
    #expect(throws: IPCalculatorError.invalidIPv4Netmask("0.0.0.255")) {
        _ = try NetworkCalculator.parseInput(["10.0.0.7/0.0.0.255"])
    }
}

@Test
func handlesIPv4PrefixBoundaries() throws {
    let zero = try NetworkCalculator.calculate("0.0.0.1/0")
    #expect(zero.network == "0.0.0.0/0")
    #expect(zero.addressCount == "4294967296")
    #expect(zero.firstAddress == "0.0.0.0")
    #expect(zero.lastAddress == "255.255.255.255")

    let host = try NetworkCalculator.calculate("192.168.1.10/32")
    #expect(host.network == "192.168.1.10/32")
    #expect(host.addressCount == "1")
    #expect(host.firstAddress == "192.168.1.10")
    #expect(host.lastAddress == "192.168.1.10")

    let pointToPoint = try NetworkCalculator.calculate("10.0.0.1/31")
    #expect(pointToPoint.network == "10.0.0.0/31")
    #expect(pointToPoint.addressCount == "2")
}

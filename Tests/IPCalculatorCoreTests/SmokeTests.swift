import Testing
@testable import IPCalculatorCore

@Test
func coreTargetLoads() {
    #expect(IPCalculatorError.unsigned32OutOfRange.userMessage == "数值超出 32 位无符号整数范围")
}

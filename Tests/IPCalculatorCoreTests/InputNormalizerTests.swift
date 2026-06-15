import Testing
@testable import IPCalculatorCore

@Test
func normalizesFullWidthPunctuationAndWhitespace() {
    #expect(InputNormalizer.normalizeInputText("  １９２．１６８．１．１０／２４ ") == "192.168.1.10/24")
    #expect(InputNormalizer.normalizeInputText("2001：db8：：") == "2001:db8::")
    #expect(InputNormalizer.normalizeInputText("48.235.24.0、30") == "48.235.24.0/30")
}

@Test
func normalizesBaseNumbers() {
    #expect(InputNormalizer.normalizeBaseNumberText(" 0xff_ff ") == "0xffff")
    #expect(InputNormalizer.normalizeBaseNumberText("１，０２４") == "1024")
}

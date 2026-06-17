import IPCalculatorCore
import Testing
@testable import IPCalculatorFeatures

@MainActor
@Test
func baseConversionWorkspacePreservesActiveFieldWhileUpdatingOtherBases() {
    let viewModel = BaseConversionViewModel()
    viewModel.update(text: "0xFF", base: .hexadecimal)

    #expect(viewModel.hexadecimalText == "0xFF")
    #expect(viewModel.decimalText == "255")
    #expect(viewModel.binaryText == "11111111")
    #expect(viewModel.invalidBase == nil)
}

@MainActor
@Test
func baseConversionWorkspaceTracksInvalidActiveField() {
    let viewModel = BaseConversionViewModel()
    viewModel.update(text: "102", base: .binary)

    #expect(viewModel.invalidBase == .binary)
    #expect(viewModel.errorMessage == "二进制只能包含 0 和 1")
}

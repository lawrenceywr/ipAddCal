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
    #expect(viewModel.binary32 == "00000000000000000000000011111111")
    #expect(viewModel.value == 255)
    #expect(viewModel.hasValue == true)
    #expect(viewModel.invalidBase == nil)
}

@MainActor
@Test
func baseConversionWorkspaceSynchronizesAndTogglesBits() {
    let viewModel = BaseConversionViewModel()
    viewModel.update(text: "255", base: .decimal)

    #expect(viewModel.binaryText == "11111111")
    #expect(viewModel.decimalText == "255")
    #expect(viewModel.hexadecimalText == "FF")
    #expect(viewModel.binary32 == "00000000000000000000000011111111")
    #expect(viewModel.value == 255)

    viewModel.toggle(bitIndex: 31)

    #expect(viewModel.value == 2_147_483_903)
    #expect(viewModel.decimalText == "2147483903")
    #expect(viewModel.hexadecimalText == "800000FF")
    #expect(viewModel.binary32 == "10000000000000000000000011111111")
}

@MainActor
@Test
func baseConversionWorkspaceTracksInvalidActiveField() {
    let viewModel = BaseConversionViewModel()
    viewModel.update(text: "102", base: .binary)

    #expect(viewModel.invalidBase == .binary)
    #expect(viewModel.errorMessage == "二进制只能包含 0 和 1")
}

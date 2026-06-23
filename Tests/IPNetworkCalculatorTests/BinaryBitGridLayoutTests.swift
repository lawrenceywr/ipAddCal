import Testing
@testable import IPNetworkCalculator

@Test
func binaryBitGridLayoutCreatesTwoRowsOfGroupedBits() {
    let layout = BinaryBitGridLayout(binary32: "00000000000000001111111111111111")

    #expect(layout.presentation == .intrinsicCompact)
    #expect(layout.rows.count == 2)
    #expect(layout.rows.map { $0.groups.map { $0.cells.count } } == [[8, 8], [8, 8]])
    #expect(layout.rows[0].groups.map(\.markerLabel) == ["31", "23"])
    #expect(layout.rows[1].groups.map(\.markerLabel) == ["15", "7"])
    #expect(layout.rows[0].groups.flatMap(\.cells).map(\.position) == Array(0..<16))
    #expect(layout.rows[1].groups.flatMap(\.cells).map(\.position) == Array(16..<32))
    #expect(layout.rows[0].groups[0].cells.map(\.bitIndex) == Array(stride(from: 31, through: 24, by: -1)))
    #expect(layout.rows[1].groups[1].cells.map(\.bitIndex) == Array(stride(from: 7, through: 0, by: -1)))
}

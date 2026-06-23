import SwiftUI

struct BinaryBitGridLayout {
    enum Presentation: Equatable {
        case intrinsicCompact
    }

    enum VerticalDensity: Equatable {
        case tight

        var groupSpacing: CGFloat { 4 }
        var groupVerticalPadding: CGFloat { 5 }
        var groupHorizontalPadding: CGFloat { 8 }
        var dividerInset: CGFloat { 5 }
        var markerFontSize: CGFloat { 10 }
    }

    struct Cell: Identifiable, Equatable {
        let position: Int
        let character: Character

        var id: Int { position }
        var bitIndex: Int { 31 - position }
    }

    struct Group: Identifiable, Equatable {
        let rowIndex: Int
        let groupIndex: Int
        let cells: [Cell]

        var id: String { "\(rowIndex)-\(groupIndex)" }
        var leadingBitIndex: Int { cells.first?.bitIndex ?? 0 }
        var trailingBitIndex: Int { cells.last?.bitIndex ?? 0 }
        var markerLabel: String { "\(leadingBitIndex)" }
    }

    struct Row: Identifiable, Equatable {
        let index: Int
        let groups: [Group]

        var id: Int { index }
    }

    let presentation: Presentation = .intrinsicCompact
    let verticalDensity: VerticalDensity = .tight
    let rows: [Row]

    init(binary32: String) {
        let bits = Self.normalizedBits(from: binary32)

        rows = stride(from: 0, to: 32, by: 16).enumerated().map { rowIndex, rowStart in
            let groups = stride(from: rowStart, to: rowStart + 16, by: 8).enumerated().map { groupIndex, groupStart in
                let cells = (0..<8).map { offset in
                    let position = groupStart + offset
                    return Cell(position: position, character: bits[position])
                }

                return Group(rowIndex: rowIndex, groupIndex: groupIndex, cells: cells)
            }

            return Row(index: rowIndex, groups: groups)
        }
    }

    private static func normalizedBits(from binary32: String) -> [Character] {
        let truncated = String(binary32.prefix(32))
        if truncated.count == 32 {
            return Array(truncated)
        }

        return Array(String(repeating: "0", count: 32 - truncated.count) + truncated)
    }
}

struct BinaryBitGridView: View {
    var binary32: String
    var onToggle: (Int) -> Void

    private var layout: BinaryBitGridLayout {
        BinaryBitGridLayout(binary32: binary32)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("32 位二进制").font(.headline)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(layout.rows.enumerated()), id: \.element.id) { rowIndex, row in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(Array(row.groups.enumerated()), id: \.element.id) { groupIndex, group in
                            VStack(alignment: .leading, spacing: layout.verticalDensity.groupSpacing) {
                                HStack(spacing: 3) {
                                    ForEach(group.cells) { cell in
                                        Button(String(cell.character)) {
                                            onToggle(cell.bitIndex)
                                        }
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .frame(width: 22, height: 22)
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }

                                Text(group.markerLabel)
                                    .font(.system(size: layout.verticalDensity.markerFontSize, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 2)
                            }
                            .padding(.horizontal, layout.verticalDensity.groupHorizontalPadding)
                            .padding(.vertical, layout.verticalDensity.groupVerticalPadding)

                            if groupIndex < row.groups.count - 1 {
                                Divider()
                                    .padding(.vertical, layout.verticalDensity.dividerInset)
                            }
                        }
                    }

                    if rowIndex < layout.rows.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

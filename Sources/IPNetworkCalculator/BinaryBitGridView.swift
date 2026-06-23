import SwiftUI

struct BinaryBitGridLayout {
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
        var bitRangeLabel: String { "\(leadingBitIndex)-\(trailingBitIndex)" }
    }

    struct Row: Identifiable, Equatable {
        let index: Int
        let groups: [Group]

        var id: Int { index }
    }

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
        VStack(alignment: .leading, spacing: 12) {
            Text("32 位二进制").font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(layout.rows) { row in
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(row.groups) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(group.bitRangeLabel) 位")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 4) {
                                    ForEach(group.cells) { cell in
                                        Button(String(cell.character)) {
                                            onToggle(cell.bitIndex)
                                        }
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .frame(width: 24, height: 24)
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }

                                HStack {
                                    Text("\(group.leadingBitIndex)")
                                    Spacer()
                                    Text("\(group.trailingBitIndex)")
                                }
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.primary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

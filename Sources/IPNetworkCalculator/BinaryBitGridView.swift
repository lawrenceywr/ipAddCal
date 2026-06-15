import SwiftUI

struct BinaryBitGridView: View {
    var binary32: String
    var onToggle: (Int) -> Void

    private var bits: [Character] {
        Array(binary32)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("32 位二进制").font(.headline)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(0..<2, id: \.self) { row in
                    GridRow {
                        ForEach(0..<16, id: \.self) { column in
                            let position = row * 16 + column
                            let bitIndex = 31 - position
                            Button(String(bits[position])) {
                                onToggle(bitIndex)
                            }
                            .font(.system(.caption, design: .monospaced).bold())
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
    }
}

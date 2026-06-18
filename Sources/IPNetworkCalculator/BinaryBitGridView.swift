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
            HStack(alignment: .center, spacing: 12) {
                ForEach(0..<4, id: \.self) { byteIndex in
                    HStack(spacing: 6) {
                        ForEach(0..<8, id: \.self) { offset in
                            let position = byteIndex * 8 + offset
                            Button(String(bits[position])) {
                                onToggle(31 - position)
                            }
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .frame(width: 28, height: 28)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
    }
}

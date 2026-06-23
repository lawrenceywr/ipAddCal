import SwiftUI
import IPCalculatorFeatures

struct TranslationDirectionPickerView: View {
    @Binding var selection: TranslationDirection

    var body: some View {
        Picker("互转方向", selection: $selection) {
            ForEach(TranslationDirection.allCases) { direction in
                Text(direction.title).tag(direction)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
    }
}

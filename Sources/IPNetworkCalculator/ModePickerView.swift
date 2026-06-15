import SwiftUI
import IPCalculatorFeatures

struct ModePickerView: View {
    @Binding var mode: CalculatorMode

    var body: some View {
        Picker("输入模式", selection: $mode) {
            ForEach(CalculatorMode.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }
}

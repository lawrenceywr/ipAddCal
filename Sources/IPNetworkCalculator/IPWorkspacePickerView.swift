import SwiftUI
import IPCalculatorFeatures

struct IPWorkspacePickerView: View {
    @Binding var selection: IPWorkspaceMode
    @Environment(\.calculatorTheme) private var theme

    var body: some View {
        Picker("IP 工作区", selection: $selection) {
            ForEach(IPWorkspaceMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .tint(theme.accentMode.tint)
    }
}

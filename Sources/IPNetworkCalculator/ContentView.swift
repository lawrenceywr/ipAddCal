import SwiftUI
import IPCalculatorFeatures

struct ContentView: View {
    @State private var viewModel = CalculatorViewModel()

    var body: some View {
        NavigationSplitView {
            HistorySidebarView(history: viewModel.history)
                .navigationTitle("历史记录")
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                header
                ModePickerView(mode: $viewModel.mode)
                if viewModel.mode == .baseConversion {
                    BaseConversionView(state: $viewModel.baseState)
                } else {
                    InputPanelView(viewModel: viewModel)
                    ResultPanelView(viewModel: viewModel)
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle("IP 地址计算器")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("IP 地址计算器")
                .font(.largeTitle.bold())
            Text("IPv4 / IPv6 网段计算、V4 到 V6、V6 到 V4 与 32 位进制转换")
                .foregroundStyle(.secondary)
        }
    }
}

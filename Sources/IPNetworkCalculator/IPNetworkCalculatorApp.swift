import SwiftUI

@main
struct IPNetworkCalculatorApp: App {
    var body: some Scene {
        Window("IP 地址计算器", id: "main") {
            ContentView()
                .frame(minWidth: 900, minHeight: 580)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

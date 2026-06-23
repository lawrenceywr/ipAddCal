import AppKit
import SwiftUI

final class AppActivationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct IPNetworkCalculatorApp: App {
    @NSApplicationDelegateAdaptor(AppActivationDelegate.self) private var appActivationDelegate
    private let theme = CalculatorTheme.defaultDark

    var body: some Scene {
        WindowGroup("IP 地址计算器") {
            ContentView()
                .frame(minWidth: 980, minHeight: 640)
                .preferredColorScheme(theme.enforcesDarkAppearance ? .dark : nil)
                .tint(theme.accentMode.tint)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

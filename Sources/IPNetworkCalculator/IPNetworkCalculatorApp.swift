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
    @AppStorage(CalculatorAppearance.storageKey) private var appearanceRawValue = CalculatorAppearance.defaultValue.rawValue

    private var selectedAppearance: CalculatorAppearance {
        CalculatorAppearance(storedValue: appearanceRawValue)
    }

    var body: some Scene {
        WindowGroup("IP 地址计算器") {
            ContentView(
                appearance: selectedAppearance,
                onToggleAppearance: {
                    appearanceRawValue = selectedAppearance.toggled.rawValue
                }
            )
                .frame(minWidth: 980, minHeight: 640)
                .preferredColorScheme(selectedAppearance.colorScheme)
                .tint(selectedAppearance.theme.accentMode.tint)
                .calculatorTheme(selectedAppearance.theme)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

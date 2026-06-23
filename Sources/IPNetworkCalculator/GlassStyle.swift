import SwiftUI

enum WorkspaceChrome {
    static let contentPadding: CGFloat = 22
    static let surfacePadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 18
    static let controlSpacing: CGFloat = 14
    static let fieldLabelSpacing: CGFloat = 6
}

private let theme = CalculatorTheme.defaultDark

private struct ChromeBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(theme.chromeBase.opacity(theme.chrome.sidebarFillOpacity))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(theme.chrome.toolbarLineOpacity))
                    .frame(height: 1)
            }
    }
}

private struct WorkspaceSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            }
    }
}

private struct PopoverSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassEffect()
    }
}

extension View {
    func calculatorChromeBackground() -> some View {
        modifier(ChromeBackgroundModifier())
    }

    func calculatorWorkspaceSurface() -> some View {
        modifier(WorkspaceSurfaceModifier())
    }

    func calculatorPopoverSurface() -> some View {
        modifier(PopoverSurfaceModifier())
    }
}

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
    let fillOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(theme.chromeBase.opacity(fillOpacity))
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

private struct CalculatorFormSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        let surface = theme.formSurface

        content
            .background(
                theme.contentBase.opacity(surface.fillOpacity),
                in: RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
                    .stroke(.white.opacity(surface.strokeOpacity), lineWidth: 1)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
                    .stroke(.white.opacity(surface.highlightOpacity), lineWidth: 0.8)
                    .mask {
                        LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .shadow(color: .black.opacity(surface.shadowOpacity), radius: 18, y: 10)
    }
}

private struct CalculatorFieldModifier: ViewModifier {
    var invalid: Bool

    func body(content: Content) -> some View {
        let field = theme.fieldChrome

        content
            .padding(.horizontal, field.horizontalPadding)
            .padding(.vertical, field.verticalPadding)
            .background(
                theme.chromeElevated.opacity(field.fillOpacity),
                in: RoundedRectangle(cornerRadius: field.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: field.cornerRadius, style: .continuous)
                    .stroke(
                        invalid ? theme.error : .white.opacity(field.strokeOpacity),
                        lineWidth: invalid ? field.invalidStrokeWidth : field.strokeWidth
                    )
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
    func calculatorChromeBackground(fillOpacity: Double = theme.chrome.sidebarFillOpacity) -> some View {
        modifier(ChromeBackgroundModifier(fillOpacity: fillOpacity))
    }

    func calculatorWorkspaceSurface() -> some View {
        modifier(WorkspaceSurfaceModifier())
    }

    func calculatorFormSurface() -> some View {
        modifier(CalculatorFormSurfaceModifier())
    }

    func calculatorPopoverSurface() -> some View {
        modifier(PopoverSurfaceModifier())
    }

    func calculatorFieldChrome(invalid: Bool = false) -> some View {
        modifier(CalculatorFieldModifier(invalid: invalid))
    }
}

import SwiftUI

enum WorkspaceChrome {
    static let contentPadding: CGFloat = 22
    static let surfacePadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 18
    static let controlSpacing: CGFloat = 14
    static let fieldLabelSpacing: CGFloat = 6
}

private struct ChromeBackgroundModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme
    let fillOpacity: Double?

    func body(content: Content) -> some View {
        content
            .background(theme.chromeBase.opacity(fillOpacity ?? theme.chrome.sidebarFillOpacity))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(theme.stroke.opacity(theme.chrome.toolbarLineOpacity))
                    .frame(height: 1)
            }
    }
}

private struct HistoryButtonChromeModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    func body(content: Content) -> some View {
        content
            .font(.headline.weight(.semibold))
            .foregroundStyle(theme.primaryLabel)
            .padding(.horizontal, theme.chrome.historyButtonHorizontalPadding)
            .padding(.vertical, theme.chrome.historyButtonVerticalPadding)
            .background(theme.chromeBase.opacity(0.62), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(theme.stroke.opacity(theme.chrome.historyButtonStrokeOpacity), lineWidth: 1)
            }
    }
}

private struct ToolbarIconButtonChromeModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    func body(content: Content) -> some View {
        content
            .font(.headline.weight(.semibold))
            .foregroundStyle(theme.primaryLabel)
            .frame(width: 38, height: 34)
            .background(theme.chromeBase.opacity(0.56), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(theme.stroke.opacity(theme.chrome.historyButtonStrokeOpacity), lineWidth: 1)
            }
    }
}

private struct WorkspaceSurfaceModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    func body(content: Content) -> some View {
        let surface = theme.workspaceSurface

        content
            .background(
                theme.contentBase.opacity(surface.fillOpacity),
                in: RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
                    .stroke(theme.stroke.opacity(surface.strokeOpacity), lineWidth: 1)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
                    .stroke(theme.highlight.opacity(surface.highlightOpacity), lineWidth: 0.8)
                    .mask {
                        LinearGradient(
                            colors: [theme.highlight, theme.highlight.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .shadow(color: theme.shadow.opacity(surface.shadowOpacity), radius: 18, y: 10)
    }
}

private struct CalculatorFormSurfaceModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    func body(content: Content) -> some View {
        let surface = theme.formSurface

        content
            .background(
                theme.contentBase.opacity(surface.fillOpacity),
                in: RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
                    .stroke(theme.stroke.opacity(surface.strokeOpacity), lineWidth: 1)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
                    .stroke(theme.highlight.opacity(surface.highlightOpacity), lineWidth: 0.8)
                    .mask {
                        LinearGradient(
                            colors: [theme.highlight, theme.highlight.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .shadow(color: theme.shadow.opacity(surface.shadowOpacity), radius: 18, y: 10)
    }
}

private struct CalculatorFieldModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme
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
                        invalid ? theme.error : theme.stroke.opacity(field.strokeOpacity),
                        lineWidth: invalid ? field.invalidStrokeWidth : field.strokeWidth
                    )
            }
    }
}

private struct PopoverSurfaceModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    func body(content: Content) -> some View {
        let surface = theme.popoverSurface

        content
            .background(
                theme.chromeElevated.opacity(surface.fillOpacity),
                in: RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
                    .stroke(theme.stroke.opacity(surface.strokeOpacity), lineWidth: 1)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: surface.cornerRadius, style: .continuous)
                    .stroke(theme.highlight.opacity(surface.highlightOpacity), lineWidth: 0.8)
                    .mask {
                        LinearGradient(
                            colors: [theme.highlight, theme.highlight.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .shadow(color: theme.shadow.opacity(surface.shadowOpacity), radius: 16, y: 8)
    }
}

extension View {
    func calculatorChromeBackground(fillOpacity: Double? = nil) -> some View {
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

    func calculatorHistoryButtonChrome() -> some View {
        modifier(HistoryButtonChromeModifier())
    }

    func calculatorToolbarIconButtonChrome() -> some View {
        modifier(ToolbarIconButtonChromeModifier())
    }
}

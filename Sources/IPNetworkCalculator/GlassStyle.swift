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

private struct WorkspaceSurfaceModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        let surface = theme.workspaceSurface

        if theme.visualStyle == .neonTactical {
            content
                .background(
                    theme.contentBase.opacity(0.90),
                    in: ChamferedRectangle(cut: 16)
                )
                .overlay {
                    ChamferedRectangle(cut: 16)
                        .stroke(theme.accentMode.tint.opacity(0.42), lineWidth: 1)
                }
                .overlay(alignment: .topLeading) {
                    Rectangle()
                        .fill(theme.accentMode.tint)
                        .frame(width: 52, height: 2)
                        .padding(.leading, 16)
                        .shadow(color: theme.accentMode.tint.opacity(theme.glowOpacity), radius: 6)
                }
                .shadow(color: theme.accentMode.tint.opacity(theme.glowOpacity * 0.34), radius: 13)
        } else {
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
}

private struct CalculatorFormSurfaceModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        let surface = theme.formSurface

        if theme.visualStyle == .neonTactical {
            content
                .background(
                    theme.contentBase.opacity(0.88),
                    in: ChamferedRectangle(cut: 16)
                )
                .overlay {
                    ChamferedRectangle(cut: 16)
                        .stroke(theme.accentSecondary.opacity(0.34), lineWidth: 1)
                }
                .overlay(alignment: .topLeading) {
                    Rectangle()
                        .fill(theme.accentSecondary)
                        .frame(width: 42, height: 2)
                        .padding(.leading, 16)
                        .shadow(color: theme.accentSecondary.opacity(theme.glowOpacity), radius: 6)
                }
                .shadow(color: theme.accentSecondary.opacity(theme.glowOpacity * 0.24), radius: 11)
        } else {
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
}

private struct CalculatorFieldModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme
    var invalid: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let field = theme.fieldChrome

        if theme.visualStyle == .neonTactical {
            content
                .foregroundStyle(invalid ? theme.error : theme.accentMode.tint)
                .padding(.horizontal, field.horizontalPadding)
                .padding(.vertical, field.verticalPadding)
                .background(
                    theme.windowBase.opacity(0.92),
                    in: ChamferedRectangle(cut: 9)
                )
                .overlay {
                    ChamferedRectangle(cut: 9)
                        .stroke(
                            invalid ? theme.error : theme.accentMode.tint.opacity(0.46),
                            lineWidth: invalid ? field.invalidStrokeWidth : field.strokeWidth
                        )
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(invalid ? theme.error : theme.accentMode.tint)
                        .frame(width: 3)
                        .padding(.vertical, 7)
                }
                .shadow(
                    color: (invalid ? theme.error : theme.accentMode.tint)
                        .opacity(theme.glowOpacity * (invalid ? 0.70 : 0.28)),
                    radius: invalid ? 7 : 4
                )
        } else {
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
}

private struct PopoverSurfaceModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        let surface = theme.popoverSurface

        if theme.visualStyle == .neonTactical {
            content
                .background(
                    theme.chromeElevated.opacity(0.96),
                    in: ChamferedRectangle(cut: 14)
                )
                .overlay {
                    ChamferedRectangle(cut: 14)
                        .stroke(theme.accentSecondary.opacity(0.52), lineWidth: 1)
                }
                .shadow(color: theme.accentSecondary.opacity(theme.glowOpacity * 0.40), radius: 13)
        } else {
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
}

private struct ResultSectionSurfaceModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        let chrome = theme.resultSection

        if theme.visualStyle == .neonTactical {
            content
                .background(
                    theme.chromeElevated.opacity(0.72),
                    in: ChamferedRectangle(cut: 12)
                )
                .overlay {
                    ChamferedRectangle(cut: 12)
                        .stroke(theme.accentSecondary.opacity(0.30), lineWidth: 1)
                }
        } else {
            content
                .background(
                    theme.chromeElevated.opacity(chrome.fillOpacity),
                    in: RoundedRectangle(cornerRadius: chrome.cornerRadius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: chrome.cornerRadius, style: .continuous)
                        .stroke(theme.stroke.opacity(chrome.strokeOpacity), lineWidth: 1)
                }
        }
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

    func calculatorResultSectionSurface() -> some View {
        modifier(ResultSectionSurfaceModifier())
    }
}

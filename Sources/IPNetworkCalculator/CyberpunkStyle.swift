import SwiftUI

struct ChamferedRectangle: InsettableShape {
    var cut: CGFloat
    private var insetAmount: CGFloat = 0

    init(cut: CGFloat) {
        self.cut = cut
    }

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let effectiveCut = min(
            max(0, cut - insetAmount),
            min(insetRect.width, insetRect.height) / 2
        )

        var path = Path()
        path.move(to: CGPoint(x: insetRect.minX + effectiveCut, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX - effectiveCut, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.minY + effectiveCut))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - effectiveCut))
        path.addLine(to: CGPoint(x: insetRect.maxX - effectiveCut, y: insetRect.maxY))
        path.addLine(to: CGPoint(x: insetRect.minX + effectiveCut, y: insetRect.maxY))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY - effectiveCut))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY + effectiveCut))
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> ChamferedRectangle {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

struct CalculatorWorkspaceBackground: View {
    @Environment(\.calculatorTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        Group {
            if theme.visualStyle == .neonTactical {
                TimelineView(.animation(minimumInterval: 1 / 24, paused: accessibilityReduceMotion)) { timeline in
                    CyberpunkBackgroundLayer(
                        theme: theme,
                        scanlinePhase: accessibilityReduceMotion ? 0.22 : animatedPhase(for: timeline.date)
                    )
                }
            } else {
                Rectangle().fill(theme.windowBase.gradient)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func animatedPhase(for date: Date) -> Double {
        date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: 5) / 5
    }
}

private struct CyberpunkBackgroundLayer: View {
    let theme: CalculatorTheme
    let scanlinePhase: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                theme.windowBase

                RadialGradient(
                    colors: [theme.accentSecondary.opacity(0.10), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: proxy.size.width * 0.55
                )

                RadialGradient(
                    colors: [theme.accentTertiary.opacity(0.045), .clear],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: proxy.size.width * 0.48
                )

                Canvas { context, size in
                    var grid = Path()
                    for x in stride(from: 0.0, through: size.width, by: 44) {
                        grid.move(to: CGPoint(x: x, y: 0))
                        grid.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for y in stride(from: 0.0, through: size.height, by: 44) {
                        grid.move(to: CGPoint(x: 0, y: y))
                        grid.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(
                        grid,
                        with: .color(theme.accentMode.tint.opacity(theme.gridOpacity)),
                        lineWidth: 0.7
                    )

                    var scanlines = Path()
                    for y in stride(from: 0.0, through: size.height, by: 4) {
                        scanlines.move(to: CGPoint(x: 0, y: y))
                        scanlines.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(
                        scanlines,
                        with: .color(.black.opacity(theme.scanlineOpacity)),
                        lineWidth: 1
                    )

                    let brightY = max(0, size.height * scanlinePhase)
                    var brightLine = Path()
                    brightLine.move(to: CGPoint(x: 0, y: brightY))
                    brightLine.addLine(to: CGPoint(x: size.width, y: brightY))
                    context.stroke(
                        brightLine,
                        with: .linearGradient(
                            Gradient(colors: [.clear, theme.accentMode.tint.opacity(0.16), .clear]),
                            startPoint: CGPoint(x: 0, y: brightY),
                            endPoint: CGPoint(x: size.width, y: brightY)
                        ),
                        lineWidth: 1
                    )
                }
            }
        }
    }
}

struct CalculatorWorkspaceHeader: View {
    @Environment(\.calculatorTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let route: String
    let title: String
    let subtitle: String

    @ViewBuilder
    var body: some View {
        if theme.visualStyle == .neonTactical {
            VStack(alignment: .leading, spacing: 6) {
                Text("> \(route) // SECURE_LINK")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(theme.accentSecondary)

                HStack(alignment: .center, spacing: 8) {
                    ZStack(alignment: .leading) {
                        Text(title)
                            .foregroundStyle(theme.accentTertiary.opacity(0.50))
                            .offset(x: -1)
                            .accessibilityHidden(true)
                        Text(title)
                            .foregroundStyle(theme.accentSecondary.opacity(0.52))
                            .offset(x: 1)
                            .accessibilityHidden(true)
                        Text(title)
                            .foregroundStyle(theme.primaryLabel)
                    }
                    .font(.system(size: 25, weight: .black, design: .monospaced))
                    .tracking(1.8)
                    .shadow(color: theme.accentMode.tint.opacity(theme.glowOpacity), radius: 9)

                    TerminalCursor(isStatic: accessibilityReduceMotion)
                }

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(theme.secondaryLabel)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

private struct TerminalCursor: View {
    @Environment(\.calculatorTheme) private var theme
    let isStatic: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.7, paused: isStatic)) { timeline in
            let tick = Int(timeline.date.timeIntervalSinceReferenceDate / 0.7)
            Rectangle()
                .fill(theme.accentMode.tint)
                .frame(width: 8, height: 22)
                .opacity(isStatic || tick.isMultiple(of: 2) ? 1 : 0.18)
                .shadow(color: theme.accentMode.tint.opacity(theme.glowOpacity), radius: 6)
        }
        .accessibilityHidden(true)
    }
}

private struct PrimaryActionChromeModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        if theme.visualStyle == .neonTactical {
            content
                .buttonStyle(.plain)
                .font(.system(.subheadline, design: .monospaced).weight(.black))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(theme.windowBase)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(theme.accentMode.tint, in: ChamferedRectangle(cut: 7))
                .overlay {
                    ChamferedRectangle(cut: 7)
                        .stroke(theme.accentMode.tint, lineWidth: 1.5)
                }
                .shadow(color: theme.accentMode.tint.opacity(theme.glowOpacity), radius: 9)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

private struct SecondaryActionChromeModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        if theme.visualStyle == .neonTactical {
            content
                .buttonStyle(.plain)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(theme.accentSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(theme.chromeElevated.opacity(0.65), in: ChamferedRectangle(cut: 5))
                .overlay {
                    ChamferedRectangle(cut: 5)
                        .stroke(theme.accentSecondary.opacity(0.58), lineWidth: 1)
                }
        } else {
            content
        }
    }
}

private struct CyberButtonChromeModifier: ViewModifier {
    @Environment(\.calculatorTheme) private var theme
    let isActive: Bool
    let accent: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if theme.visualStyle == .neonTactical {
            let resolvedAccent = accent ?? theme.accentMode.tint
            content
                .foregroundStyle(isActive ? theme.windowBase : theme.primaryLabel)
                .background(
                    isActive ? resolvedAccent : theme.chromeElevated.opacity(0.38),
                    in: ChamferedRectangle(cut: 7)
                )
                .overlay {
                    ChamferedRectangle(cut: 7)
                        .stroke(resolvedAccent.opacity(isActive ? 1 : 0.32), lineWidth: 1)
                }
                .shadow(
                    color: resolvedAccent.opacity(isActive ? theme.glowOpacity : 0),
                    radius: isActive ? 7 : 0
                )
        } else {
            content
        }
    }
}

extension View {
    func calculatorPrimaryActionChrome() -> some View {
        modifier(PrimaryActionChromeModifier())
    }

    func calculatorSecondaryActionChrome() -> some View {
        modifier(SecondaryActionChromeModifier())
    }

    func calculatorCyberButtonChrome(isActive: Bool, accent: Color? = nil) -> some View {
        modifier(CyberButtonChromeModifier(isActive: isActive, accent: accent))
    }
}

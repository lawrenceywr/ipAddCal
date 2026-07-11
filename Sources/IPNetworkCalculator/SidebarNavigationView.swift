import SwiftUI
import IPCalculatorFeatures

struct SidebarNavigationView: View {
    @Binding var selection: AppWorkspace
    @Environment(\.calculatorTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(AppWorkspace.allCases) { workspace in
                Button {
                    selection = workspace
                } label: {
                    Text(workspace.title)
                        .font(sidebarFont)
                        .tracking(theme.visualStyle == .neonTactical ? 0.7 : 0)
                        .foregroundStyle(rowForeground(for: workspace))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background { rowBackground(for: workspace) }
                        .shadow(
                            color: theme.accentMode.tint.opacity(
                                theme.visualStyle == .neonTactical && selection == workspace
                                    ? theme.glowOpacity
                                    : 0
                            ),
                            radius: 7
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            if theme.visualStyle == .neonTactical {
                Text("NODE: LOCALHOST\nLATENCY: 0.4MS\nSTATUS: ONLINE")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(theme.accentSecondary.opacity(0.58))
                    .padding(.leading, 10)
                    .padding(.bottom, 12)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(theme.accentSecondary)
                            .frame(width: 2)
                            .padding(.vertical, 2)
                    }
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var sidebarFont: Font {
        if theme.visualStyle == .neonTactical {
            return .system(.subheadline, design: .monospaced).weight(.bold)
        }

        return .headline.weight(.semibold)
    }

    private func rowForeground(for workspace: AppWorkspace) -> Color {
        if theme.visualStyle == .neonTactical && selection == workspace {
            return theme.windowBase
        }

        if selection == workspace {
            return Color.white.opacity(0.96)
        }

        return theme.primaryLabel
    }

    @ViewBuilder
    private func rowBackground(for workspace: AppWorkspace) -> some View {
        if theme.visualStyle == .neonTactical {
            ChamferedRectangle(cut: 7)
                .fill(selection == workspace ? theme.accentMode.tint : theme.chromeElevated.opacity(0.20))
                .overlay {
                    ChamferedRectangle(cut: 7)
                        .stroke(
                            theme.accentMode.tint.opacity(selection == workspace ? 1 : 0.18),
                            lineWidth: 1
                        )
                }
        } else {
            RoundedRectangle(
                cornerRadius: theme.chrome.sidebarRowCornerRadius,
                style: .continuous
            )
            .fill(selection == workspace ? theme.accentMode.tint : .clear)
        }
    }
}

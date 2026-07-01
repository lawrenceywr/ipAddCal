import SwiftUI
import IPCalculatorFeatures

struct SidebarNavigationView: View {
    @Binding var selection: AppWorkspace
    private let theme = CalculatorTheme.defaultDark

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(AppWorkspace.allCases) { workspace in
                Button {
                    selection = workspace
                } label: {
                    Text(workspace.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.94))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            selection == workspace ? theme.accentMode.tint : .clear,
                            in: RoundedRectangle(
                                cornerRadius: theme.chrome.sidebarRowCornerRadius,
                                style: .continuous
                            )
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

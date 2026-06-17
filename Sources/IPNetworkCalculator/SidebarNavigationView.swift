import SwiftUI
import IPCalculatorFeatures

struct SidebarNavigationView: View {
    @Binding var selection: AppWorkspace

    var body: some View {
        List(AppWorkspace.allCases, selection: listSelection) { workspace in
            Text(workspace.title)
                .tag(workspace)
        }
        .listStyle(.sidebar)
    }

    private var listSelection: Binding<AppWorkspace?> {
        Binding(
            get: { selection },
            set: { newValue in
                guard let newValue else { return }
                selection = newValue
            }
        )
    }
}

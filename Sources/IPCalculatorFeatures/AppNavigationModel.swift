import Observation

@MainActor
@Observable
public final class AppNavigationModel {
    public var selectedWorkspace: AppWorkspace
    public var selectedIPMode: IPWorkspaceMode
    public var isHistoryPresented: Bool

    public init(
        selectedWorkspace: AppWorkspace = .ipCalculation,
        selectedIPMode: IPWorkspaceMode = .network,
        isHistoryPresented: Bool = false
    ) {
        self.selectedWorkspace = selectedWorkspace
        self.selectedIPMode = selectedIPMode
        self.isHistoryPresented = isHistoryPresented
    }
}

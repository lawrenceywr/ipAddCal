import SwiftUI

struct GlassPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassEffect()
    }
}

extension View {
    func calculatorGlassPanel() -> some View {
        modifier(GlassPanel())
    }
}

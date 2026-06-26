import SwiftUI

enum ThemeAccentMode: Equatable {
    case calculatorOrange

    var tint: Color { Color(red: 1.0, green: 0.584, blue: 0.0) }
}

enum ThemeGlassIntensity: Equatable {
    case elevated
}

enum ThemeSurfaceContrast: Equatable {
    case clearBoundaries
}

struct CalculatorSurfaceStyle: Equatable {
    let cornerRadius: CGFloat
    let fillOpacity: Double
    let strokeOpacity: Double
    let highlightOpacity: Double
    let shadowOpacity: Double
}

struct CalculatorChromeStyle: Equatable {
    let sidebarFillOpacity: Double
    let detailFillOpacity: Double
    let toolbarLineOpacity: Double
    let sidebarFloatingCornerRadius: CGFloat
    let sidebarRowCornerRadius: CGFloat
    let titleItemBorderOpacity: Double
    let historyButtonHorizontalPadding: CGFloat
    let historyButtonVerticalPadding: CGFloat
    let historyButtonStrokeOpacity: Double
    let integratedSidebarWidth: CGFloat
    let integratedSidebarDividerOpacity: Double
}

struct CalculatorFieldChrome: Equatable {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let fillOpacity: Double
    let strokeOpacity: Double
    let strokeWidth: CGFloat
    let invalidStrokeWidth: CGFloat
}

struct CalculatorSectionChrome: Equatable {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let rowSpacing: CGFloat
    let headerSpacing: CGFloat
    let fillOpacity: Double
    let strokeOpacity: Double
}

struct CalculatorTheme: Equatable {
    let enforcesDarkAppearance: Bool
    let accentMode: ThemeAccentMode
    let glassIntensity: ThemeGlassIntensity
    let surfaceContrast: ThemeSurfaceContrast
    let windowBase = Color(red: 0.115, green: 0.121, blue: 0.139)
    let chromeBase = Color(red: 0.148, green: 0.156, blue: 0.178)
    let chromeElevated = Color(red: 0.178, green: 0.186, blue: 0.212)
    let contentBase = Color(red: 0.205, green: 0.214, blue: 0.244)
    let divider = Color.white.opacity(0.10)
    let secondaryLabel = Color.white.opacity(0.64)
    let error = Color(red: 0.93, green: 0.42, blue: 0.42)
    let workspaceSurface: CalculatorSurfaceStyle
    let formSurface: CalculatorSurfaceStyle
    let popoverSurface: CalculatorSurfaceStyle

    static let defaultDark = CalculatorTheme(
        enforcesDarkAppearance: true,
        accentMode: .calculatorOrange,
        glassIntensity: .elevated,
        surfaceContrast: .clearBoundaries,
        workspaceSurface: CalculatorSurfaceStyle(
            cornerRadius: 20,
            fillOpacity: 0.78,
            strokeOpacity: 0.18,
            highlightOpacity: 0.24,
            shadowOpacity: 0.22
        ),
        formSurface: CalculatorSurfaceStyle(
            cornerRadius: 20,
            fillOpacity: 0.78,
            strokeOpacity: 0.18,
            highlightOpacity: 0.24,
            shadowOpacity: 0.22
        ),
        popoverSurface: CalculatorSurfaceStyle(
            cornerRadius: 18,
            fillOpacity: 0.86,
            strokeOpacity: 0.16,
            highlightOpacity: 0.28,
            shadowOpacity: 0.24
        )
    )
}

extension CalculatorTheme {
    var chrome: CalculatorChromeStyle {
        CalculatorChromeStyle(
            sidebarFillOpacity: 0.96,
            detailFillOpacity: 0.92,
            toolbarLineOpacity: 0.06,
            sidebarFloatingCornerRadius: 0,
            sidebarRowCornerRadius: 10,
            titleItemBorderOpacity: 0,
            historyButtonHorizontalPadding: 16,
            historyButtonVerticalPadding: 8,
            historyButtonStrokeOpacity: 0.14,
            integratedSidebarWidth: 168,
            integratedSidebarDividerOpacity: 0.10
        )
    }

    var fieldChrome: CalculatorFieldChrome {
        CalculatorFieldChrome(
            cornerRadius: 12,
            horizontalPadding: 12,
            verticalPadding: 10,
            fillOpacity: 0.92,
            strokeOpacity: 0.14,
            strokeWidth: 1,
            invalidStrokeWidth: 1.3
        )
    }

    var resultSection: CalculatorSectionChrome {
        CalculatorSectionChrome(
            cornerRadius: 16,
            horizontalPadding: 14,
            verticalPadding: 12,
            rowSpacing: 12,
            headerSpacing: 8,
            fillOpacity: 0.76,
            strokeOpacity: 0.12
        )
    }
}

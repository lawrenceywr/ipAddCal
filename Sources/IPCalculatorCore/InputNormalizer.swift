import Foundation

public enum InputNormalizer {
    private static let translation: [Character: Character] = [
        "、": "/",
        "。": ".",
        "．": ".",
        "：": ":",
        "／": "/",
        "，": ",",
    ]

    public static func normalizeInputText(_ text: String) -> String {
        let translated = String(text.map { translation[$0] ?? $0 })
        let folded = translated.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? translated
        return folded.filter { !$0.isWhitespace }
    }

    public static func normalizeFieldText(_ text: String) -> String {
        normalizeInputText(text)
            .replacingOccurrences(of: #"/{2,}"#, with: "/", options: .regularExpression)
    }

    public static func normalizeBaseNumberText(_ text: String) -> String {
        normalizeInputText(text)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
}

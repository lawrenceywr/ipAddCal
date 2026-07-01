import AppKit
import SwiftUI
import IPCalculatorCore

struct NormalizingTextField: NSViewRepresentable {
    let title: String
    @Binding var text: String
    let onSubmit: () -> Void

    init(_ title: String, text: Binding<String>, onSubmit: @escaping () -> Void) {
        self.title = title
        self._text = text
        self.onSubmit = onSubmit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.stringValue = text
        textField.placeholderString = title
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.usesSingleLineMode = true
        textField.lineBreakMode = .byClipping
        textField.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        context.coordinator.text = $text
        context.coordinator.onSubmit = onSubmit
        textField.placeholderString = title
        if textField.stringValue != text {
            textField.stringValue = text
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var onSubmit: () -> Void

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            self.text = text
            self.onSubmit = onSubmit
        }

        func controlTextDidChange(_ notification: Notification) {
            normalize(notification.object as? NSTextField)
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            normalize(notification.object as? NSTextField)
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else {
                return false
            }

            normalize(control as? NSTextField)
            onSubmit()
            return true
        }

        private func normalize(_ textField: NSTextField?) {
            guard let textField else {
                return
            }

            let rawText = textField.stringValue
            let normalizedText = InputNormalizer.normalizeFieldText(rawText)

            if rawText != normalizedText {
                let editor = textField.currentEditor()
                let selectedRange = editor?.selectedRange ?? NSRange(location: rawText.utf16.count, length: 0)
                textField.stringValue = normalizedText

                if let editor {
                    let adjustedLocation = selectedRange.location + normalizedText.utf16.count - rawText.utf16.count
                    editor.selectedRange = NSRange(
                        location: min(max(0, adjustedLocation), normalizedText.utf16.count),
                        length: 0
                    )
                }
            }

            if text.wrappedValue != normalizedText {
                text.wrappedValue = normalizedText
            }
        }
    }
}

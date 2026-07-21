import AppKit
import SwiftUI
import Testing
@testable import IPNetworkCalculator

@MainActor
@Test
func normalizingTextFieldCoordinatorRewritesAppKitTextFieldValue() {
    var text = ""
    let binding = Binding(
        get: { text },
        set: { text = $0 }
    )
    let textField = NSTextField()
    let coordinator = NormalizingTextField.Coordinator(text: binding, onSubmit: {})

    textField.stringValue = "１９２。１６８。１。１０、２４"
    coordinator.controlTextDidChange(
        Notification(name: NSControl.textDidChangeNotification, object: textField)
    )

    #expect(textField.stringValue == "192.168.1.10/24")
    #expect(text == "192.168.1.10/24")
}

@MainActor
@Test
func normalizingTextFieldCoordinatorSubmitsLiveFieldEditorValue() {
    var text = "48.235.24.0/30"
    var submittedText: String?
    let binding = Binding(
        get: { text },
        set: { text = $0 }
    )
    let textField = NSTextField()
    let coordinator = NormalizingTextField.Coordinator(
        text: binding,
        onSubmit: { submittedText = text }
    )

    textField.stringValue = text
    let fieldEditor = NSTextView()
    fieldEditor.string = "４８。２３５。２５。０、３０"
    let handled = coordinator.control(
        textField,
        textView: fieldEditor,
        doCommandBy: #selector(NSResponder.insertNewline(_:))
    )

    #expect(handled)
    #expect(textField.stringValue == "48.235.25.0/30")
    #expect(fieldEditor.string == "48.235.25.0/30")
    #expect(text == "48.235.25.0/30")
    #expect(submittedText == "48.235.25.0/30")
}

@MainActor
@Test
func normalizingTextFieldCoordinatorReportsKeyboardFocus() {
    var text = ""
    var focused = false
    let textBinding = Binding(
        get: { text },
        set: { text = $0 }
    )
    let focusBinding = Binding(
        get: { focused },
        set: { focused = $0 }
    )
    let textField = NSTextField()
    let coordinator = NormalizingTextField.Coordinator(
        text: textBinding,
        isFocused: focusBinding,
        onSubmit: {}
    )

    coordinator.controlTextDidBeginEditing(
        Notification(name: NSControl.textDidBeginEditingNotification, object: textField)
    )
    #expect(focused)

    coordinator.controlTextDidEndEditing(
        Notification(name: NSControl.textDidEndEditingNotification, object: textField)
    )
    #expect(!focused)
}

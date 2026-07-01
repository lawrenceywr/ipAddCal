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
func normalizingTextFieldCoordinatorSubmitsReturnKeyAfterNormalizing() {
    var text = ""
    var submitCount = 0
    let binding = Binding(
        get: { text },
        set: { text = $0 }
    )
    let textField = NSTextField()
    let coordinator = NormalizingTextField.Coordinator(
        text: binding,
        onSubmit: { submitCount += 1 }
    )

    textField.stringValue = "２００１：ｄｂ８：："
    let handled = coordinator.control(
        textField,
        textView: NSTextView(),
        doCommandBy: #selector(NSResponder.insertNewline(_:))
    )

    #expect(handled)
    #expect(textField.stringValue == "2001:db8::")
    #expect(text == "2001:db8::")
    #expect(submitCount == 1)
}

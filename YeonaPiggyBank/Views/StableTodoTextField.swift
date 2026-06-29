import SwiftUI
import UIKit

/// 한글 IME 조합이 SwiftUI TextField에서 끊기는 문제를 피하기 위한 입력 필드
struct StableTodoTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 17)
        field.textColor = Self.resolvedTextColor(for: field.traitCollection)
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .done
        field.delegate = context.coordinator
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingChanged(_:)),
            for: .editingChanged
        )
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.textColor = Self.resolvedTextColor(for: uiView.traitCollection)
        guard !uiView.isFirstResponder else { return }
        if uiView.text != text {
            uiView.text = text
        }
    }

    private static func resolvedTextColor(for traits: UITraitCollection) -> UIColor {
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        @objc func editingChanged(_ sender: UITextField) {
            text = sender.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

/// 비밀번호 화면이 열릴 때 키보드·커서를 자동으로 올립니다.
struct AutoFocusSecureField: View {
    @Binding var text: String
    var placeholder: String = "비밀번호"
    var useRoundedBorder = false
    var refocusToken = 0

    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if useRoundedBorder {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField(placeholder, text: $text)
            }
        }
        .focused($isFocused)
        .onAppear { requestFocus() }
        .onChange(of: refocusToken) { _, _ in requestFocus() }
    }

    private func requestFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isFocused = true
        }
    }
}

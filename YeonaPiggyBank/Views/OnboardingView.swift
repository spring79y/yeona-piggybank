import SwiftUI

struct OnboardingView: View {
    @ObservedObject var store: PiggyBankStore
    @ObservedObject var todoStore: TodoStore
    var onComplete: () -> Void

    @State private var page = 0
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var childLastName = ""
    @State private var childFirstName = ""
    @State private var passwordError: String?
    @FocusState private var passwordFocused: Bool

    private let totalPages = 4

    var body: some View {
        ZStack {
            LinearGradient(
                colors: AppTheme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index <= page ? Color(hex: "FF6B8A") : Color(hex: "FF6B8A").opacity(0.25))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)

                Group {
                    switch page {
                    case 0: welcomePage
                    case 1: passwordPage
                    case 2: namePage
                    default: guidePage
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(page)
                .transition(.opacity)

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
        .onChange(of: page) { _, newValue in
            guard newValue == 1 else {
                passwordFocused = false
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                if page == 1 { passwordFocused = true }
            }
        }
    }

    private var welcomePage: some View {
        onboardingPage(
            emoji: "🐷",
            title: "내 아이의 저금통",
            body: "용돈·할 일·칭찬을\n한곳에서 관리해요.\n\n엄마가 먼저 설정하면\n아이가 바로 사용할 수 있어요."
        )
    }

    private var passwordPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                onboardingPage(
                    emoji: "🔐",
                    title: "비밀번호 만들기",
                    body: "입금·출금·칭찬스티커는\n엄마 비밀번호로 보호해요."
                )

                VStack(spacing: 12) {
                    onboardingSecureField("비밀번호", text: $password)
                        .focused($passwordFocused)
                    onboardingSecureField("비밀번호 확인", text: $confirmPassword)

                    if let passwordError {
                        Text(passwordError)
                            .font(.caption.bold())
                            .foregroundStyle(Color(hex: "FF3B30"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 32)
                .onChange(of: password) { _, _ in passwordError = nil }
                .onChange(of: confirmPassword) { _, _ in passwordError = nil }
            }
            .padding(.vertical, 24)
        }
    }

    private var namePage: some View {
        ScrollView {
            VStack(spacing: 20) {
                onboardingPage(
                    emoji: "✨",
                    title: "아이 이름 (선택)",
                    body: "이름을 넣으면 앱 곳곳에\n아이 이름이 표시돼요.\n나중에 엄마가 관리에서 바꿀 수 있어요."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("성 (선택)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.secondaryText)
                    onboardingTextField("성", text: $childLastName)
                }
                .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 8) {
                    Text("이름")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.secondaryText)
                    onboardingTextField("이름", text: $childFirstName)
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 24)
        }
    }

    private var guidePage: some View {
        ScrollView {
            VStack(spacing: 18) {
                onboardingPage(
                    emoji: "📋",
                    title: "이렇게 사용해요",
                    body: nil
                )

                guideCard(emoji: "📝", title: "할 일", detail: "엄마가 관리 → 할일 관리에서\n평일·주말 할 일을 게시해요.")
                guideCard(emoji: "🏦", title: "나눔 · 용돈 · 저축", detail: "세 저금통에 용돈을 나눠 넣어요.\n저축은 월이율로 매일 밤 9시에 수익이 붙어요.")
                guideCard(emoji: "❤️", title: "칭찬판 & 돌림판", detail: "칭찬스티커 10개를 채우면\n돌림판 보상이 열려요!")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if page > 0 {
                Button {
                    withAnimation { page -= 1 }
                } label: {
                    Text("이전")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "6B8EAE"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "6B8EAE").opacity(0.4), lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Button {
                advance()
            } label: {
                Text(page == totalPages - 1 ? "시작하기" : "다음")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B8A"), Color(hex: "4ECDC4")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func onboardingPage(emoji: String, title: String, body: String?) -> some View {
        VStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 64))
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
            if let body {
                Text(body)
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func guideCard(emoji: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(Color(hex: "FF6B8A"))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.elevatedCardBackground.opacity(0.92))
                .shadow(color: Color(hex: "FF6B8A").opacity(0.08), radius: 8, y: 4)
        )
    }

    private func onboardingTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 17))
            .foregroundStyle(AppTheme.fieldText)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(onboardingFieldBackground)
    }

    private func onboardingSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(.system(size: 17))
            .foregroundStyle(AppTheme.fieldText)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(onboardingFieldBackground)
    }

    private var onboardingFieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(AppTheme.fieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.fieldBorder, lineWidth: 1)
            )
    }

    private func advance() {
        switch page {
        case 0:
            withAnimation { page = 1 }
        case 1:
            guard validatePassword() else { return }
            store.setPassword(password)
            withAnimation { page = 2 }
        case 2:
            let first = childFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !first.isEmpty {
                store.setChildName(
                    lastName: childLastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    firstName: first
                )
            }
            withAnimation { page = 3 }
        default:
            finish()
        }
    }

    private func validatePassword() -> Bool {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            passwordError = "비밀번호를 입력해 주세요."
            passwordFocused = true
            return false
        }
        guard trimmed == confirmPassword else {
            passwordError = "비밀번호가 일치하지 않아요."
            return false
        }
        passwordError = nil
        return true
    }

    private func finish() {
        OnboardingSettings.markCompleted()
        TodoWidgetRefresher.reload()
        HapticFeedback.success()
        onComplete()
    }
}

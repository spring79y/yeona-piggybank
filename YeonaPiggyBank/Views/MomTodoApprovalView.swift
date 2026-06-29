import SwiftUI

struct MomTodoApprovalView: View {
    @ObservedObject var store: PiggyBankStore
    @ObservedObject var todoStore: TodoStore

    @State private var password = ""
    @State private var unlocked = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var passwordRefocusToken = 0
    @State private var passwordError: String?

    private var pendingItems: [TodoItem] {
        todoStore.pendingItems()
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("아이가 해냈다고 표시한 할 일을\n확인하고 승인하거나 거절해 주세요.\n승인·거절·보상은 시간 제한이 없어요.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if !unlocked {
                AutoFocusSecureField(
                    text: $password,
                    placeholder: "비밀번호",
                    useRoundedBorder: true,
                    refocusToken: passwordRefocusToken
                )
                .onChange(of: password) { _, newValue in
                    guard !newValue.isEmpty else { return }
                    passwordError = nil
                }

                if let passwordError {
                    Text(passwordError)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF3B30"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    unlock()
                } label: {
                    Text("확인")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "6B8EAE")))
                }
                .disabled(password.isEmpty)
            } else if todoStore.canClaimReward() {
                rewardClaimPrompt
            } else if pendingItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "4ECDC4"))
                    Text("완료 대기 중인 할 일이 없어요")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(pendingItems) { item in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.text)
                                        .font(.body.bold())
                                    Text("완료 대기")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color(hex: "FF8C42"))
                                }
                                Spacer(minLength: 8)
                                HStack(spacing: 8) {
                                    Button("거절") {
                                        reject(item)
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color(hex: "FF3B30"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .stroke(Color(hex: "FF3B30"), lineWidth: 1.5)
                                    )

                                    Button("승인") {
                                        approve(item)
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color(hex: "4ECDC4")))
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
                .frame(maxHeight: 260)

                Button {
                    approveAll()
                } label: {
                    Text("전체 승인 (\(pendingItems.count)개)")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "FF6B8A")))
                }
            }
        }
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var rewardClaimPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "FFB347"))

            Text("모든 할 일이 승인되었어요!\n1,000원을 나눔·용돈·저축에 나눠 넣어 주세요.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                todoStore.showRewardSheet = true
            } label: {
                Text("보상 나누기")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "FF6B8A")))
            }
        }
        .padding(.vertical, 12)
    }

    private func unlock() {
        guard store.hasPassword else {
            passwordError = "먼저 비밀번호를 만들어 주세요."
            return
        }
        guard store.verifyPassword(password) else {
            passwordError = "비밀번호가 틀렸어요."
            password = ""
            passwordRefocusToken += 1
            return
        }
        passwordError = nil
        unlocked = true
        password = ""
    }

    private func approve(_ item: TodoItem) {
        guard todoStore.momApprove(id: item.id) else { return }
        HapticFeedback.success()
        alertMessage = "「\(item.text)」을(를) 승인했어요!"
        showAlert = true
    }

    private func reject(_ item: TodoItem) {
        guard todoStore.momReject(id: item.id) else { return }
        HapticFeedback.light()
        alertMessage = "「\(item.text)」을(를) 거절했어요.\n게시판에서 다시 할 수 있어요."
        showAlert = true
    }

    private func approveAll() {
        let count = todoStore.momApproveAllPending()
        guard count > 0 else { return }
        HapticFeedback.success()
        alertMessage = "할 일 \(count)개를 모두 승인했어요!"
        showAlert = true
    }
}

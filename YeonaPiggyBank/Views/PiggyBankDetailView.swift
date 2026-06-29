import SwiftUI

struct PiggyBankDetailView: View {
    @ObservedObject var store: PiggyBankStore
    let type: PiggyBankType
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var isDeposit = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var dismissAfterAlert = false
    @State private var momPassword = ""
    @State private var transactionError: String?
    @State private var momPasswordRefocusToken = 0

    private var bank: PiggyBank { store.bank(for: type) }

    private var requiresMomPassword: Bool {
        true
    }

    private var momPasswordCaption: String {
        switch type {
        case .give:
            return isDeposit ? "나눔 입금은 엄마 비밀번호가 필요해요" : "나눔 출금은 엄마 비밀번호가 필요해요"
        case .spend:
            return "용돈 입금·출금은 엄마 비밀번호가 필요해요"
        case .save:
            return isDeposit ? "저축 입금은 엄마 비밀번호가 필요해요" : "저축 출금은 엄마 비밀번호가 필요해요"
        }
    }

    private var withdrawButtonTitle: String {
        type == .save ? "용돈으로 출금하기" : "출금하기"
    }

    private var accentColor: Color {
        Color(hex: type.colorHex)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 14) {
                        PiggyBankJarView(bank: bank, style: .modal, animateOnBalanceChange: true)

                        VStack(spacing: 6) {
                            Text("현재 잔액")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(bank.formattedBalance)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(accentColor)

                            if type == .save {
                                SaveCountdownView(compact: false, bonusRatePercent: store.saveBonusRatePercent)
                                saveRulesHint
                            } else if type == .give {
                                giveRulesHint
                            } else if type == .spend {
                                spendRulesHint
                            }
                        }

                        Picker("거래 유형", selection: $isDeposit) {
                            Text("입금").tag(true)
                            Text("출금").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 32)
                        .onChange(of: isDeposit) { _, _ in
                            transactionError = nil
                            momPassword = ""
                        }

                        if requiresMomPassword {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(momPasswordCaption)
                                    .font(.caption.bold())
                                    .foregroundStyle(Color(hex: "FF6B8A"))

                                AutoFocusSecureField(
                                    text: $momPassword,
                                    placeholder: "엄마 비밀번호",
                                    useRoundedBorder: true,
                                    refocusToken: momPasswordRefocusToken
                                )
                                .onChange(of: momPassword) { _, newValue in
                                    guard !newValue.isEmpty else { return }
                                    transactionError = nil
                                }
                            }
                            .padding(.horizontal, 32)
                        }

                        if let transactionError {
                            Text(transactionError)
                                .font(.caption.bold())
                                .foregroundStyle(Color(hex: "FF3B30"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        VStack(spacing: 12) {
                            HStack {
                                TextField("금액을 입력하세요", text: $amountText)
                                    .keyboardType(.numberPad)
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(.systemGray6))
                                    )
                                Text("원")
                                    .font(.title3.bold())
                            }
                            .padding(.horizontal, 32)

                            HStack(spacing: 10) {
                                ForEach([100, 500, 1000], id: \.self) { amount in
                                    Button("+\(amount.formatted)원") {
                                        addQuickAmount(amount)
                                    }
                                    .buttonStyle(QuickAmountButtonStyle(color: accentColor))
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                }

                VStack(spacing: 10) {
                    Button {
                        requestTransaction()
                    } label: {
                        Text(isDeposit ? "입금하기" : withdrawButtonTitle)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isDeposit ? accentColor : Color.orange)
                            )
                    }
                    .disabled(
                        (!isDeposit && type == .save && !MonthEndHelper.canWithdrawSave())
                        || (requiresMomPassword && momPassword.isEmpty)
                    )
                    .opacity(!isDeposit && type == .save && !MonthEndHelper.canWithdrawSave() ? 0.45 : 1)

                    Button {
                        dismiss()
                    } label: {
                        Text("확인")
                            .font(.headline.bold())
                            .foregroundStyle(accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(accentColor, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .background(.ultraThinMaterial)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                LinearGradient(
                    colors: [accentColor.opacity(0.08), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle(type.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("알림", isPresented: $showAlert) {
                Button("확인", role: .cancel) {
                    if dismissAfterAlert {
                        dismissAfterAlert = false
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func requestTransaction() {
        transactionError = nil

        if requiresMomPassword {
            guard store.hasPassword else {
                transactionError = "엄마가 관리에서 비밀번호를 만들어 주세요."
                return
            }
            guard store.verifyPassword(momPassword) else {
                transactionError = "비밀번호가 틀렸어요."
                momPassword = ""
                momPasswordRefocusToken += 1
                return
            }
        }

        performTransaction()
    }

    private func addQuickAmount(_ amount: Int) {
        let current = Int(amountText.filter(\.isNumber)) ?? 0
        amountText = String(current + amount)
    }

    private func performTransaction() {
        guard let amount = Int(amountText.filter(\.isNumber)), amount > 0 else {
            alertMessage = "올바른 금액을 입력해 주세요."
            showAlert = true
            return
        }

        if isDeposit {
            store.deposit(to: type, amount: amount)
            HapticFeedback.light()
            alertMessage = "\(amount.formatted)원이 입금되었어요!"
        } else if type == .save {
            guard MonthEndHelper.canWithdrawSave() else {
                alertMessage = "저축 출금은 매월 1일부터 5일까지 가능해요."
                showAlert = true
                return
            }
            guard store.withdrawSaveToSpend(amount: amount) else {
                alertMessage = "잔액이 부족해요. 현재 \(bank.formattedBalance)이에요."
                showAlert = true
                return
            }
            HapticFeedback.success()
            alertMessage = "\(amount.formatted)원이 저축에서 용돈으로 이동했어요!"
        } else {
            if amount > bank.balance {
                alertMessage = "잔액이 부족해요. 현재 \(bank.formattedBalance)이에요."
                showAlert = true
                return
            }
            store.withdraw(from: type, amount: amount)
            HapticFeedback.light()
            alertMessage = "\(amount.formatted)원이 출금되었어요!"
        }

        amountText = ""
        if requiresMomPassword {
            momPassword = ""
        }
        dismissAfterAlert = true
        showAlert = true
    }

    private var giveRulesHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("나눔 안내", systemImage: "info.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "FF6B8A"))
            Text("• 입금·출금 모두 엄마 비밀번호가 필요해요")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "FF6B8A").opacity(0.08))
        )
        .padding(.horizontal, 32)
    }

    private var spendRulesHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("용돈 안내", systemImage: "info.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "FFB347"))
            Text("• 입금·출금 모두 엄마 비밀번호가 필요해요")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "FFB347").opacity(0.08))
        )
        .padding(.horizontal, 32)
    }

    private var saveRulesHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("저축 안내", systemImage: "info.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "4ECDC4"))
            Text("• 월 \(store.saveBonusRatePercent)% 이율로 매일 밤 9시에 수익이 붙어요\n• 출금은 1~5일만 가능해요\n• 출금하면 용돈으로 이동해요\n• 입금·출금 모두 엄마 비밀번호가 필요해요")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "4ECDC4").opacity(0.08))
        )
        .padding(.horizontal, 32)
    }
}

struct QuickAmountButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(configuration.isPressed ? 0.3 : 0.15))
            )
            .foregroundStyle(color)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

private extension Int {
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

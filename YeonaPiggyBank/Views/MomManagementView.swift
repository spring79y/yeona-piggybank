import SwiftUI

enum MomManagementMode: String, CaseIterable, Identifiable, Hashable {
    case todo = "할 일 관리"
    case todoApproval = "할 일 승인"
    case childName = "아이 이름"
    case reminder = "할 일 알림"
    case saveBonus = "투자 수익"
    case create = "비밀번호 생성"
    case change = "비밀번호 변경"
    case clearPassword = "비밀번호 초기화"
    case reset = "전체 초기화"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .todo: return "checklist"
        case .todoApproval: return "hand.thumbsup.fill"
        case .childName: return "person.fill"
        case .reminder: return "bell.fill"
        case .saveBonus: return "chart.line.uptrend.xyaxis"
        case .create: return "lock.fill"
        case .change: return "key.fill"
        case .clearPassword: return "lock.open.fill"
        case .reset: return "trash.fill"
        }
    }

    var isDestructive: Bool { self == .reset }
}

private struct MomSettingsSection: Identifiable {
    let id: String
    let title: String?
    let modes: [MomManagementMode]
}

struct MomManagementView: View {
    @ObservedObject var store: PiggyBankStore
    @ObservedObject var stickerStore: StickerStore
    @ObservedObject var todoStore: TodoStore
    var onFullReset: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    init(
        store: PiggyBankStore,
        stickerStore: StickerStore,
        todoStore: TodoStore,
        onFullReset: (() -> Void)? = nil
    ) {
        self.store = store
        self.stickerStore = stickerStore
        self.todoStore = todoStore
        self.onFullReset = onFullReset
    }

    @State private var oldPassword = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var resetPassword = ""
    @State private var clearPasswordInput = ""
    @State private var todoPassword = ""
    @State private var todoUnlocked = false
    @State private var todoPasswordError: String?
    @State private var todoPasswordRefocusToken = 0
    @State private var detailMessage: String?
    @State private var detailMessageIsError = true
    @State private var changePasswordRefocusToken = 0
    @State private var clearPasswordRefocusToken = 0
    @State private var resetPasswordRefocusToken = 0
    @State private var reminderEnabled = TodoReminderScheduler.isEnabled
    @State private var saveBonusRate = SaveBonusSettings.ratePercent
    @State private var childLastNameInput = ""
    @State private var childFirstNameInput = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var rewardGiveAmount = 0
    @State private var rewardSpendAmount = 0
    @State private var rewardSaveAmount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if todoStore.canClaimReward() {
                        rewardPendingBanner
                    }

                    profileHeader

                    ForEach(settingSections) { section in
                        MomSettingsGroup(title: section.title) {
                            ForEach(Array(section.modes.enumerated()), id: \.element.id) { index, mode in
                                NavigationLink(value: mode) {
                                    MomSettingsRow(
                                        title: mode.rawValue,
                                        icon: mode.icon,
                                        isDestructive: mode.isDestructive
                                    )
                                }
                                .buttonStyle(.plain)

                                if index < section.modes.count - 1 {
                                    MomSettingsDivider()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .navigationTitle("엄마가 관리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .navigationDestination(for: MomManagementMode.self) { mode in
                momDetailView(for: mode)
            }
            .sheet(isPresented: $todoStore.showRewardSheet) {
                TodoRewardSheet(
                    giveAmount: $rewardGiveAmount,
                    spendAmount: $rewardSpendAmount,
                    saveAmount: $rewardSaveAmount,
                    onConfirm: confirmTodoReward
                )
            }
            .onChange(of: todoStore.showRewardSheet) { _, isShowing in
                if isShowing {
                    rewardGiveAmount = 0
                    rewardSpendAmount = 0
                    rewardSaveAmount = 0
                }
            }
            .alert("알림", isPresented: $showAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Menu

    private var rewardPendingBanner: some View {
        Button {
            todoStore.showRewardSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: "FF6B8A"))

                VStack(alignment: .leading, spacing: 4) {
                    Text("할 일 보상 대기 중")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("1,000원을 나눔·용돈·저축에 나눠 넣어 주세요")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.mutedLabel)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.chevron)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "FF6B8A").opacity(0.35), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var profileHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color(hex: "FF6B8A"))
            }

            Text(store.childFirstName.isEmpty ? "엄마 관리" : "\(store.childFirstName) 엄마")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            Text("설정을 선택해 주세요")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.mutedLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var settingSections: [MomSettingsSection] {
        if store.hasPassword {
            return [
                MomSettingsSection(id: "todo", title: "할 일", modes: [.todo, .todoApproval, .reminder]),
                MomSettingsSection(id: "child", title: "아이", modes: [.childName]),
                MomSettingsSection(id: "bank", title: "저금통", modes: [.saveBonus]),
                MomSettingsSection(id: "security", title: "보안", modes: [.change, .clearPassword]),
                MomSettingsSection(id: "danger", title: nil, modes: [.reset]),
            ]
        }
        return [
            MomSettingsSection(id: "setup", title: nil, modes: [.create]),
            MomSettingsSection(id: "danger", title: nil, modes: [.reset]),
        ]
    }

    @ViewBuilder
    private func momDetailView(for mode: MomManagementMode) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if let detailMessage {
                    Text(detailMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(detailMessageIsError ? Color(hex: "FF3B30") : Color(hex: "4ECDC4"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }

                switch mode {
                case .todo:
                    todoSection
                case .todoApproval:
                    todoApprovalSection
                case .childName:
                    childNameSection
                case .reminder:
                    reminderSection
                case .saveBonus:
                    saveBonusSection
                case .create:
                    createSection
                case .change:
                    changeSection
                case .clearPassword:
                    clearPasswordSection
                case .reset:
                    resetSection
                }
            }
            .padding(16)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(mode.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            detailMessage = nil
        }
        .onDisappear {
            detailMessage = nil
            if mode == .todo {
                todoUnlocked = false
                todoPassword = ""
                todoPasswordError = nil
            }
        }
    }

    // MARK: - Detail sections

    private var todoApprovalSection: some View {
        MomTodoApprovalView(store: store, todoStore: todoStore)
    }

    private var childNameSection: some View {
        VStack(spacing: 16) {
            MomSettingsInfoCard(
                text: "아이 이름을 설정하면 앱 곳곳에 이름이 표시돼요.\n앱에서는 이름만 사용해요."
            )

            MomSettingsGroup(title: nil) {
                VStack(spacing: 0) {
                    MomSettingsFieldRow(title: "성", placeholder: "성 (선택)", text: $childLastNameInput)
                    MomSettingsDivider()
                    MomSettingsFieldRow(title: "이름", placeholder: "이름", text: $childFirstNameInput)
                }
            }

            actionButton(title: "저장하기", color: Color(hex: "FF6B8A")) {
                saveChildName()
            }

            Text(store.childFirstName.isEmpty
                 ? "현재: 내 아이의 저금통"
                 : "현재: \(store.childFirstName)의 저금통")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "6B8EAE"))
                .multilineTextAlignment(.center)
        }
        .onAppear {
            childLastNameInput = store.childLastName
            childFirstNameInput = store.childFirstName
        }
    }

    private func saveChildName() {
        let first = childFirstNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !first.isEmpty else {
            alertMessage = "이름을 입력해 주세요."
            showAlert = true
            return
        }
        store.setChildName(
            lastName: childLastNameInput.trimmingCharacters(in: .whitespacesAndNewlines),
            firstName: first
        )
        TodoReminderScheduler.reschedule(todoStore: todoStore)
        TodoWidgetRefresher.reload()
        alertMessage = "\(first) 이름으로 저장했어요!"
        showAlert = true
    }

    private var saveBonusSection: some View {
        VStack(spacing: 16) {
            MomSettingsInfoCard(
                text: "저축 수익은 월이율이에요.\n매일 밤 9시에 하루치 이자가 붙어요.\n수익률을 선택해 주세요."
            )

            MomSettingsGroup(title: "월이율") {
                Picker("월이율", selection: $saveBonusRate) {
                    ForEach(SaveBonusSettings.allowedRates, id: \.self) { rate in
                        Text("\(rate)%").tag(rate)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .onChange(of: saveBonusRate) { _, rate in
                    store.setSaveBonusRatePercent(rate)
                }
            }

            Text("현재 설정: 월 \(store.saveBonusRatePercent)% (매일 밤 9시 지급)")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "4ECDC4"))
                .multilineTextAlignment(.center)

            MomSettingsInfoCard(
                title: "하루 이자 예시",
                text: "잔액 1,000원 · 월 50% · 30일 달 → 하루 \(SaveBonusSettings.dailyInterestAmount(for: 1000, rate: 50))원 (10원 단위 반올림)",
                tint: Color(hex: "4ECDC4")
            )

            MomSettingsInfoCard(
                title: "저축 출금 규칙",
                text: "• 저축 출금은 매월 1~5일만 가능해요\n• 출금하면 용돈으로 이동해요\n• 나눔·용돈 입출금은 엄마 비밀번호가 필요해요",
                tint: Color(hex: "FF8C42")
            )
        }
        .onAppear { saveBonusRate = store.saveBonusRatePercent }
    }

    private var reminderSection: some View {
        VStack(spacing: 16) {
            MomSettingsInfoCard(
                text: "오후 5시부터 9시까지 매시 정각에\n미완료 할 일을 알려줘요."
            )

            MomSettingsGroup(title: nil) {
                Toggle(isOn: $reminderEnabled) {
                    Text("할 일 알림 켜기")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.primaryText)
                }
                .tint(Color(hex: "FF6B8A"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: reminderEnabled) { _, enabled in
                    TodoReminderScheduler.isEnabled = enabled
                    if enabled {
                        TodoReminderScheduler.requestAuthorizationIfNeeded { granted in
                            if !granted {
                                alertMessage = "알림 권한이 필요해요. 설정 앱에서 허용해 주세요."
                                showAlert = true
                            }
                            TodoReminderScheduler.reschedule(todoStore: todoStore)
                        }
                    } else {
                        TodoReminderScheduler.reschedule(todoStore: todoStore)
                    }
                }
            }

            Text("알림 문구: \"\(ChildNameSettings.todoReminder)\"")
                .font(.caption)
                .foregroundStyle(AppTheme.mutedLabel)
                .multilineTextAlignment(.center)
        }
        .onAppear { reminderEnabled = TodoReminderScheduler.isEnabled }
    }

    private var todoSection: some View {
        VStack(spacing: 16) {
            if todoUnlocked {
                MomTodoEditorView(todoStore: todoStore)
            } else {
                MomSettingsInfoCard(text: "할 일을 등록하려면\n비밀번호를 입력해 주세요")

                MomSettingsGroup(title: nil) {
                    MomSettingsSecureFieldRow(
                        title: "비밀번호",
                        text: $todoPassword,
                        autoFocus: true,
                        refocusToken: todoPasswordRefocusToken
                    )
                }
                .onChange(of: todoPassword) { _, newValue in
                    guard !newValue.isEmpty else { return }
                    todoPasswordError = nil
                }

                if let todoPasswordError {
                    Text(todoPasswordError)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF3B30"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }

                actionButton(title: "확인", color: Color(hex: "6B8EAE")) {
                    unlockTodoEditor()
                }
                .disabled(todoPassword.isEmpty)
            }
        }
    }

    private var createSection: some View {
        VStack(spacing: 16) {
            MomSettingsInfoCard(text: "입금·출금에 사용할\n비밀번호를 만들어 주세요")

            MomSettingsGroup(title: nil) {
                VStack(spacing: 0) {
                    MomSettingsSecureFieldRow(title: "비밀번호", text: $password, autoFocus: true)
                    MomSettingsDivider()
                    MomSettingsSecureFieldRow(title: "비밀번호 확인", text: $confirmPassword)
                }
            }
            .onChange(of: password) { _, _ in detailMessage = nil }
            .onChange(of: confirmPassword) { _, newValue in
                guard !newValue.isEmpty else { return }
                detailMessage = nil
            }

            actionButton(title: "비밀번호 생성", color: Color(hex: "4ECDC4")) {
                saveNewPassword(requireOld: false)
            }
            .disabled(password.isEmpty || confirmPassword.isEmpty)
        }
    }

    private var changeSection: some View {
        VStack(spacing: 16) {
            MomSettingsInfoCard(text: "현재 비밀번호 확인 후\n새 비밀번호로 변경해요")

            MomSettingsGroup(title: nil) {
                VStack(spacing: 0) {
                    MomSettingsSecureFieldRow(
                        title: "현재 비밀번호",
                        text: $oldPassword,
                        autoFocus: true,
                        refocusToken: changePasswordRefocusToken
                    )
                    MomSettingsDivider()
                    MomSettingsSecureFieldRow(title: "새 비밀번호", text: $password)
                    MomSettingsDivider()
                    MomSettingsSecureFieldRow(title: "새 비밀번호 확인", text: $confirmPassword)
                }
            }
            .onChange(of: oldPassword) { _, newValue in
                guard !newValue.isEmpty else { return }
                detailMessage = nil
            }
            .onChange(of: password) { _, _ in detailMessage = nil }
            .onChange(of: confirmPassword) { _, newValue in
                guard !newValue.isEmpty else { return }
                detailMessage = nil
            }

            actionButton(title: "비밀번호 변경", color: Color(hex: "4ECDC4")) {
                saveNewPassword(requireOld: true)
            }
            .disabled(oldPassword.isEmpty || password.isEmpty || confirmPassword.isEmpty)
        }
    }

    private var clearPasswordSection: some View {
        VStack(spacing: 16) {
            MomSettingsInfoCard(text: "비밀번호 확인 후 삭제해요.\n다시 비밀번호 생성부터 시작할 수 있어요.")

            MomSettingsGroup(title: nil) {
                MomSettingsSecureFieldRow(
                    title: "현재 비밀번호",
                    text: $clearPasswordInput,
                    autoFocus: true,
                    refocusToken: clearPasswordRefocusToken
                )
            }
            .onChange(of: clearPasswordInput) { _, newValue in
                guard !newValue.isEmpty else { return }
                detailMessage = nil
            }

            actionButton(title: "비밀번호 초기화", color: Color(hex: "9B59B6")) {
                performClearPassword()
            }
            .disabled(clearPasswordInput.isEmpty)
        }
    }

    private var resetSection: some View {
        VStack(spacing: 16) {
            MomSettingsInfoCard(
                text: "저금통·칭찬스티커·할 일·아이 이름·비밀번호를 모두 지우고\n처음 설치한 상태로 돌아가요. 안내 화면이 다시 나와요.",
                tint: Color(hex: "FF3B30")
            )

            MomSettingsGroup(title: nil) {
                MomSettingsSecureFieldRow(
                    title: "비밀번호",
                    text: $resetPassword,
                    autoFocus: true,
                    refocusToken: resetPasswordRefocusToken
                )
            }
            .onChange(of: resetPassword) { _, newValue in
                guard !newValue.isEmpty else { return }
                detailMessage = nil
            }

            actionButton(title: "초기화하기", color: Color(hex: "FF3B30")) {
                performReset()
            }
            .disabled(resetPassword.isEmpty)
        }
    }

    // MARK: - Actions

    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(color))
        }
    }

    private func unlockTodoEditor() {
        guard store.hasPassword else {
            todoPasswordError = "먼저 비밀번호를 만들어 주세요."
            return
        }
        guard store.verifyPassword(todoPassword) else {
            todoPasswordError = "비밀번호가 틀렸어요."
            todoPassword = ""
            todoPasswordRefocusToken += 1
            return
        }
        todoPasswordError = nil
        todoUnlocked = true
        todoPassword = ""
    }

    private func saveNewPassword(requireOld: Bool) {
        if requireOld {
            guard store.verifyPassword(oldPassword) else {
                detailMessageIsError = true
                detailMessage = "현재 비밀번호가 틀렸어요."
                oldPassword = ""
                changePasswordRefocusToken += 1
                return
            }
        }
        guard !password.isEmpty else {
            detailMessageIsError = true
            detailMessage = "비밀번호를 입력해 주세요."
            return
        }
        guard password == confirmPassword else {
            detailMessageIsError = true
            detailMessage = "비밀번호가 일치하지 않아요."
            return
        }
        store.setPassword(password)
        clearFields()
        detailMessageIsError = false
        detailMessage = "비밀번호가 저장되었어요!"
    }

    private func performClearPassword() {
        guard store.hasPassword else {
            detailMessageIsError = true
            detailMessage = "설정된 비밀번호가 없어요."
            return
        }
        guard store.verifyPassword(clearPasswordInput) else {
            detailMessageIsError = true
            detailMessage = "비밀번호가 틀렸어요."
            clearPasswordInput = ""
            clearPasswordRefocusToken += 1
            return
        }
        store.clearPassword()
        clearPasswordInput = ""
        detailMessageIsError = false
        detailMessage = "비밀번호가 초기화되었어요. 새로 만들어 주세요!"
    }

    private func performReset() {
        guard store.hasPassword else {
            detailMessageIsError = true
            detailMessage = "먼저 비밀번호를 만들어 주세요."
            return
        }
        guard store.verifyPassword(resetPassword) else {
            detailMessageIsError = true
            detailMessage = "비밀번호가 틀렸어요."
            resetPassword = ""
            resetPasswordRefocusToken += 1
            return
        }
        store.resetAll()
        stickerStore.resetAll()
        todoStore.resetAll()
        store.clearPassword()
        OnboardingSettings.reset()
        TodoReminderScheduler.resetToDefault()
        reminderEnabled = TodoReminderScheduler.isEnabled
        saveBonusRate = SaveBonusSettings.ratePercent
        childLastNameInput = ""
        childFirstNameInput = ""
        resetPassword = ""
        clearFields()
        todoUnlocked = false
        TodoWidgetRefresher.reload()
        dismiss()
        onFullReset?()
    }

    private func clearFields() {
        oldPassword = ""
        password = ""
        confirmPassword = ""
    }

    private func confirmTodoReward() {
        _ = todoStore.applyReward(
            give: rewardGiveAmount,
            spend: rewardSpendAmount,
            saveAmount: rewardSaveAmount,
            bankStore: store
        )
        rewardGiveAmount = 0
        rewardSpendAmount = 0
        rewardSaveAmount = 0
    }
}

// MARK: - Kakao-style settings components

private struct MomSettingsGroup<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.mutedLabel)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 0) {
                content
            }
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct MomSettingsRow: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(isDestructive ? Color(hex: "FF3B30") : AppTheme.mutedLabel)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(isDestructive ? Color(hex: "FF3B30") : AppTheme.primaryText)

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.chevron)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct MomSettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(AppTheme.separator)
            .padding(.leading, 54)
    }
}

private struct MomSettingsFieldRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 52, alignment: .leading)

            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct MomSettingsSecureFieldRow: View {
    let title: String
    @Binding var text: String
    var autoFocus = false
    var refocusToken = 0

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            SecureField("입력", text: $text)
                .font(.system(size: 16))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppTheme.primaryText)
                .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear { requestFocusIfNeeded() }
        .onChange(of: refocusToken) { _, _ in requestFocusIfNeeded() }
    }

    private func requestFocusIfNeeded() {
        guard autoFocus else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isFocused = true
        }
    }
}

private struct MomSettingsInfoCard: View {
    var title: String?
    let text: String
    var tint: Color = AppTheme.mutedLabel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.mutedLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground)
        )
    }
}

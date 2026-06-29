import SwiftUI

struct MainView: View {
    @Binding var scrollToTodo: Bool
    @StateObject private var store = PiggyBankStore()
    @StateObject private var stickerStore = StickerStore()
    @StateObject private var todoStore = TodoStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedType: PiggyBankType?
    @State private var historyType: PiggyBankType?
    @State private var showMomManagement = false
    @State private var showPraiseSticker = false
    @State private var jarPulseTokens: [PiggyBankType: Int] = [:]
    @State private var showOnboarding = false
    @State private var contentWidth: CGFloat = 390
    @State private var selectedJarType: PiggyBankType = .spend
    @State private var rewardGiveAmount = 0
    @State private var rewardSpendAmount = 0
    @State private var rewardSaveAmount = 0

    init(scrollToTodo: Binding<Bool> = .constant(false)) {
        _scrollToTodo = scrollToTodo
    }

    private var jarCardWidth: CGFloat {
        LayoutMetrics.jarCardWidth(screenWidth: contentWidth)
    }

    private var usesJarCarousel: Bool {
        LayoutMetrics.usesJarCarousel(width: contentWidth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: AppTheme.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                CuteBackgroundView()
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: usesJarCarousel ? 20 : 28) {
                            VStack(spacing: 8) {
                                Text(store.appTitle)
                                    .font(.system(
                                        size: LayoutMetrics.appTitleSize(width: contentWidth),
                                        weight: .bold,
                                        design: .rounded
                                    ))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "FF6B8A"), Color(hex: "4ECDC4")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(2)
                            }
                            .padding(.top, usesJarCarousel ? 12 : 20)
                            .padding(.horizontal, 8)

                            TodoBoardView(
                                todoStore: todoStore,
                                bankStore: store,
                                contentWidth: contentWidth
                            )
                            .id("todo-board")
                            .onAppear {
                                todoStore.ensureCycleDay()
                                TodoReminderScheduler.reschedule(todoStore: todoStore)
                                TodoWidgetRefresher.reload()
                            }

                            piggyBankSection

                            Text(usesJarCarousel
                                 ? "위에서 나눔 · 용돈 · 저축을 선택해 보세요"
                                 : "저금통을 터치하면 입금과 출금을 할 수 있어요")
                                .font(usesJarCarousel ? .caption : .body)
                                .foregroundStyle(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)

                            actionButtons
                                .padding(.top, 4)
                                .padding(.bottom, 24)
                        }
                        .trackWidth($contentWidth)
                    }
                    .onChange(of: scrollToTodo) { _, shouldScroll in
                        guard shouldScroll else { return }
                        withAnimation(.easeInOut(duration: 0.45)) {
                            proxy.scrollTo("todo-board", anchor: .top)
                        }
                        scrollToTodo = false
                    }
                }
            }
            .onChange(of: todoStore.pulseToken) { _, _ in
                pulseJars(todoStore.lastRewardBankTypes)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                todoStore.ensureCycleDay()
                TodoReminderScheduler.reschedule(todoStore: todoStore)
            }
            .sheet(item: $selectedType) { type in
                PiggyBankDetailView(store: store, type: type)
                    .presentationDetents(
                        DeviceLayout.isPhone ? [.large] : [.fraction(0.92)]
                    )
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $historyType) { type in
                TransactionHistoryView(store: store, type: type)
            }
            .sheet(isPresented: $showMomManagement) {
                MomManagementView(store: store, stickerStore: stickerStore, todoStore: todoStore) {
                    showMomManagement = false
                    showOnboarding = true
                }
                .presentationDetents([.fraction(0.92)])
                .presentationDragIndicator(.visible)
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
            .sheet(isPresented: $showPraiseSticker) {
                PraiseStickerView(
                    store: store,
                    stickerStore: stickerStore,
                    onSpendJarPulse: { pulseJars([.spend]) }
                )
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    todoStore.ensureCycleDay()
                    store.tickScheduledTasks()
                    TodoWidgetRefresher.reload()
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(store: store, todoStore: todoStore) {
                    showOnboarding = false
                }
            }
            .onAppear {
                if store.hasPassword || OnboardingSettings.hasCompleted {
                    if store.hasPassword && !OnboardingSettings.hasCompleted {
                        OnboardingSettings.markCompleted()
                    }
                } else {
                    showOnboarding = true
                }
            }
        }
    }

    @ViewBuilder
    private var piggyBankSection: some View {
        if usesJarCarousel {
            VStack(spacing: 12) {
                Picker("저금통", selection: $selectedJarType) {
                    ForEach(PiggyBankType.allCases) { type in
                        Text(type.name).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                TabView(selection: $selectedJarType) {
                    ForEach(PiggyBankType.allCases) { type in
                        piggyBankColumn(for: type)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 4)
                            .tag(type)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: LayoutMetrics.jarSectionHeight(cardWidth: jarCardWidth))
            }
        } else {
            HStack(
                alignment: .top,
                spacing: LayoutMetrics.iPadJarColumnSpacing(screenWidth: contentWidth)
            ) {
                ForEach(PiggyBankType.allCases) { type in
                    piggyBankColumn(for: type)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .padding(.horizontal, LayoutMetrics.iPadJarSidePadding(screenWidth: contentWidth))
            .frame(maxWidth: .infinity)
        }
    }

    private func piggyBankColumn(for type: PiggyBankType) -> some View {
        VStack(spacing: 10) {
            Button {
                selectedType = type
            } label: {
                PiggyBankJarView(
                    bank: store.bank(for: type),
                    cardWidth: jarCardWidth,
                    externalPulseToken: jarPulseTokens[type, default: 0],
                    saveBonusRatePercent: store.saveBonusRatePercent
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Button {
                historyType = type
            } label: {
                Label("이력", systemImage: "list.bullet.clipboard")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: type.colorHex))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(Color(hex: type.colorHex).opacity(0.35), lineWidth: 1.5)
                            .background(Capsule().fill(Color(hex: type.colorHex).opacity(0.08)))
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionButtons: some View {
        HStack(spacing: usesJarCarousel ? 12 : 16) {
            Button {
                showPraiseSticker = true
            } label: {
                Label("칭찬스티커", systemImage: "heart.fill")
                    .font(usesJarCarousel ? .subheadline.bold() : .body.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, usesJarCarousel ? 16 : 20)
                    .padding(.vertical, usesJarCarousel ? 10 : 12)
                    .background(
                        Capsule()
                            .fill(Color(hex: "FF6B8A"))
                    )
            }

            Button {
                showMomManagement = true
            } label: {
                Label("엄마가 관리", systemImage: "person.crop.circle.fill")
                    .font(usesJarCarousel ? .subheadline.bold() : .body.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, usesJarCarousel ? 16 : 20)
                    .padding(.vertical, usesJarCarousel ? 10 : 12)
                    .background(
                        Capsule()
                            .fill(Color(hex: "4ECDC4"))
                    )
            }
        }
    }

    private func pulseJars(_ types: [PiggyBankType]) {
        for type in types {
            jarPulseTokens[type, default: 0] += 1
        }
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

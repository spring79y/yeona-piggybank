import SwiftUI

struct TodoBoardView: View {
    @ObservedObject var todoStore: TodoStore
    @ObservedObject var bankStore: PiggyBankStore
    var contentWidth: CGFloat = 390

    @State private var selectedItem: TodoItem?
    @State private var showLockedAlert = false
    @State private var showPendingAlert = false

    private var visibleItems: [TodoItem] {
        todoStore.visibleItems()
    }

    private var schedule: TodoSchedule {
        todoStore.activeSchedule()
    }

    private var boardHeight: CGFloat {
        LayoutMetrics.todoBoardHeight(width: contentWidth)
    }

    private var postItSize: CGFloat {
        LayoutMetrics.todoPostItSize(width: contentWidth)
    }

    private var nightMessageFontSize: CGFloat {
        LayoutMetrics.nightMessageSize(width: contentWidth)
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            board
            footer
        }
        .padding(.horizontal, 16)
        .onAppear { todoStore.ensureCycleDay() }
        .sheet(item: $selectedItem) { item in
            TodoActionSheet(
                item: item,
                onDone: {
                    if todoStore.markPendingApproval(id: item.id) {
                        HapticFeedback.success()
                    }
                    selectedItem = nil
                },
                onCancel: { selectedItem = nil }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .alert("알림", isPresented: $showLockedAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("9시가 넘어서 할 일을 변경할 수 없어요.")
        }
        .alert("알림", isPresented: $showPendingAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("엄마 확인을 기다리고 있어요.")
        }
        .overlay {
            if todoStore.showCelebration {
                celebrationOverlay
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("오늘의 할 일")
                .font(.title2.bold())
                .foregroundStyle(Color(hex: "8B6914"))
            Text(todoStore.activeScheduleKey() == .weekend ? "주말 할 일" : "평일 할 일")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var board: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "C4956A"), Color(hex: "A67C52"), Color(hex: "8B6914")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "6B4423"), lineWidth: 4)
                )
                .shadow(color: Color(hex: "6B4423").opacity(0.35), radius: 8, y: 4)

            TodoBoardGraffitiView(firstName: bankStore.childFirstName)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 6)
                .padding(.bottom, 8)
                .zIndex(3)
                .allowsHitTesting(false)

            if !todoStore.hasPublishedSchedule() {
                Text("엄마가 할 일을 올려 주면\n포스트잇이 여기에 붙어요")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "FFF8E7").opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding()
            } else if visibleItems.isEmpty {
                Text("오늘은 등록된\n할 일이 없어요")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "FFF8E7").opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                            let layout = TodoPostItLayout.layouts[index % TodoPostItLayout.layouts.count]
                            Button {
                                handlePostItTap(item)
                            } label: {
                                TodoPostItView(
                                    item: item,
                                    colorName: layout.colorName,
                                    scale: postItSize / 120
                                )
                            }
                            .buttonStyle(.plain)
                            .frame(width: postItSize, height: postItSize)
                            .contentShape(Rectangle())
                            .offset(
                                x: geo.size.width * layout.left,
                                y: geo.size.height * layout.top
                            )
                            .rotationEffect(.degrees(layout.rotate))
                            .zIndex(Double(index))
                        }
                    }
                }
            }

            if TodoCycleHelper.isLocked() {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.25))
                    .allowsHitTesting(false)
            }

            if let night = todoStore.nightMessage(), !night.isSuccess {
                Text(night.text)
                    .font(.system(size: nightMessageFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "FFF8E7"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .minimumScaleFactor(0.35)
                    .lineLimit(6)
                    .padding(.horizontal, 20)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    .zIndex(5)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: boardHeight)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            if TodoCycleHelper.isActivePeriod() {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text("오늘 밤 9시까지 \(TodoCycleHelper.countdownText(from: context.date))")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "8B6914"))
                        .monospacedDigit()
                }
            }

            if todoStore.hasPendingApprovals(), TodoCycleHelper.isActivePeriod() {
                Text("엄마 확인을 기다리는 할 일이 있어요")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "FF8C42"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            if todoStore.canClaimReward() {
                Button {
                    todoStore.showRewardSheet = true
                } label: {
                    Label("할 일 보상 받기", systemImage: "gift.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFB347"), Color(hex: "FF6B8A")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            if let night = todoStore.nightMessage(), night.isSuccess {
                Text(night.text)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "4ECDC4"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(ChildNameSettings.celebrationPraise)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("🎉✨🎊")
                    .font(.largeTitle)
            }
        }
    }

    private func handlePostItTap(_ item: TodoItem) {
        guard TodoCycleHelper.isActivePeriod() else {
            showLockedAlert = true
            return
        }
        guard !item.completed else { return }
        guard !item.isAwaitingMomApproval else {
            showPendingAlert = true
            return
        }
        selectedItem = item
    }
}

struct TodoActionSheet: View {
    let item: TodoItem
    let onDone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("할 일")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(item.text)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("엄마가 확인하면 완료돼요")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                onDone()
            } label: {
                Text("해냄!")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "4ECDC4"))
                    )
            }
            .padding(.horizontal, 32)

            Button("닫기", role: .cancel) {
                onCancel()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 28)
        .padding(.bottom, 16)
    }
}

struct TodoPostItView: View {
    let item: TodoItem
    let colorName: String
    var scale: CGFloat = 1

    private var bgColor: Color {
        switch colorName {
        case "yellow": return Color(hex: "FFF9C4")
        case "pink": return Color(hex: "F8BBD9")
        case "mint": return Color(hex: "B2DFDB")
        case "blue": return Color(hex: "BBDEFB")
        case "peach": return Color(hex: "FFCCBC")
        default: return Color(hex: "FFF9C4")
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 2)
                .fill(bgColor)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 2)

            Circle()
                .fill(Color(hex: "C0392B"))
                .frame(width: 8 * scale, height: 8 * scale)
                .offset(y: -4 * scale)

            Text(item.text)
                .font(AppFonts.postItHandwriting(size: 26 * scale))
                .foregroundStyle(Color(hex: "333333"))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.65)
                .padding(.horizontal, 6 * scale)
                .padding(.top, 12 * scale)

            if item.completed {
                ZStack {
                    Color.white.opacity(0.35)
                    Image(systemName: "checkmark")
                        .font(.system(size: 44 * scale, weight: .bold))
                        .foregroundStyle(Color(hex: "43A047"))
                }
            } else if item.isAwaitingMomApproval {
                ZStack {
                    Color.white.opacity(0.25)
                    VStack(spacing: 4 * scale) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 28 * scale, weight: .bold))
                            .foregroundStyle(Color(hex: "FF8C42"))
                        Text("대기")
                            .font(AppFonts.postItHandwriting(size: 16 * scale))
                            .foregroundStyle(Color(hex: "FF8C42"))
                    }
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 12, y: 0))
                        path.addLine(to: CGPoint(x: 12, y: 12))
                        path.closeSubpath()
                    }
                    .fill(bgColor.opacity(0.6))
                    .frame(width: 12 * scale, height: 12 * scale)
                }
            }
        }
    }
}

struct TodoRewardSheet: View {
    @Binding var giveAmount: Int
    @Binding var spendAmount: Int
    @Binding var saveAmount: Int
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var total: Int { giveAmount + spendAmount + saveAmount }
    private var isValid: Bool { total == TodoCycleHelper.rewardAmount }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("1,000원을 나눔 · 용돈 · 저축에 나눠 넣어요")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                VStack(spacing: 16) {
                    rewardRow(title: "나눔", emoji: "❤️", value: $giveAmount)
                    rewardRow(title: "용돈", emoji: "🛍️", value: $spendAmount)
                    rewardRow(title: "저축", emoji: "🏦", value: $saveAmount)
                }

                HStack {
                    Text("합계")
                        .font(.headline)
                    Spacer()
                    Text("\(total.formatted)원 / 1,000원")
                        .font(.headline)
                        .foregroundStyle(isValid ? Color(hex: "4ECDC4") : .red)
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .navigationTitle("할 일 보상")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") {
                        onConfirm()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
    }

    private func rewardRow(title: String, emoji: String, value: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            Text("\(emoji) \(title)")
                .font(.title3.bold())
                .frame(width: 120, alignment: .leading)

            Spacer()

            Text("\(value.wrappedValue.formatted)원")
                .font(.title3.bold())
                .monospacedDigit()
                .frame(minWidth: 72, alignment: .trailing)

            Stepper("", value: value, in: 0...TodoCycleHelper.rewardAmount, step: 100)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
        .onChange(of: value.wrappedValue) { _, newVal in
            clampTotal(changed: title, newValue: newVal)
        }
    }

    private func clampTotal(changed: String, newValue: Int) {
        let others: Int
        switch changed {
        case "나눔": others = spendAmount + saveAmount
        case "용돈": others = giveAmount + saveAmount
        default: others = giveAmount + spendAmount
        }
        let maxAllowed = TodoCycleHelper.rewardAmount - others
        if newValue > maxAllowed {
            switch changed {
            case "나눔": giveAmount = max(0, maxAllowed)
            case "용돈": spendAmount = max(0, maxAllowed)
            default: saveAmount = max(0, maxAllowed)
            }
        }
    }
}

private extension Int {
    var formatted: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

struct TodoBoardGraffitiView: View {
    let firstName: String

    private var displayName: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasName: Bool {
        !displayName.isEmpty
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.12))
                .frame(width: 108, height: 72)
                .rotationEffect(.degrees(-6))

            VStack(spacing: 4) {
                Text("✨")
                    .font(.caption2)
                    .rotationEffect(.degrees(12))
                if hasName {
                    HStack(spacing: 4) {
                        Text(displayName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "FF6B8A"))
                        Text("화이팅!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "FFD54F"))
                    }
                    .rotationEffect(.degrees(-4))
                    .shadow(color: Color(hex: "FF6B8A").opacity(0.25), radius: 0, x: 1, y: 1)
                } else {
                    Text("화이팅!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "FFD54F"))
                        .rotationEffect(.degrees(8))
                        .shadow(color: Color(hex: "F57F17").opacity(0.3), radius: 0, x: 1, y: 1)
                }
                Text("♥ ★")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "FF6B8A").opacity(0.85))
                    .rotationEffect(.degrees(-4))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .opacity(0.92)
    }
}

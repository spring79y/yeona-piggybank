import SwiftUI

struct PraiseStickerView: View {
    @ObservedObject var store: PiggyBankStore
    @ObservedObject var stickerStore: StickerStore
    var onSpendJarPulse: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var showCelebration = false
    @State private var showWheel = false
    @State private var showFireworks = false
    @State private var showQuotaPanel = false
    @State private var quotaInput = ""
    @State private var quotaPassword = ""
    @State private var quotaAlertMessage = ""
    @State private var showQuotaAlert = false
    @State private var selectedSticker: String?
    @State private var pendingSpendAnimation = false
    @State private var draggingSticker: String?
    @State private var dragLocation: CGPoint = .zero
    @State private var slotFrames: [Int: CGRect] = [:]

    private let stickerSpaceName = "stickerRoot"

    private let slotLayout: [(x: CGFloat, y: CGFloat, rotate: Double)] = [
        (0.28, 0.24, -8), (0.72, 0.24, 8), (0.40, 0.36, -5), (0.60, 0.36, 5),
        (0.50, 0.20, 0), (0.24, 0.50, -10), (0.76, 0.50, 10), (0.38, 0.64, -5),
        (0.62, 0.64, 5), (0.50, 0.78, 0),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
                    progressHeader
                    quotaSection

                    Text(stickerStore.canPlace
                         ? (selectedSticker != nil
                            ? "칸을 터치하거나 스티커를 끌어다 붙여 주세요"
                            : "스티커를 터치 후 칸을 누르거나\n바로 끌어다 붙여 주세요")
                         : "엄마가 칭찬스티커 붙이기를 눌러 주세요")
                        .font(.caption)
                        .foregroundStyle(stickerStore.canPlace ? Color(hex: "FF6B8A") : Color(hex: "E8456A"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(alignment: .top, spacing: 12) {
                        scatteredStickerBoard
                        stickerPalette
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)

                if let draggingSticker {
                    Text(draggingSticker)
                        .font(.system(size: 40))
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        .position(dragLocation)
                        .allowsHitTesting(false)
                        .transition(.scale)
                }

                if showFireworks {
                    FireworksView()
                        .ignoresSafeArea()
                }

                if showCelebration {
                    celebrationOverlay
                }

                if showWheel {
                    wheelOverlay
                }

                if showQuotaPanel {
                    quotaOverlay
                }
            }
            .coordinateSpace(name: stickerSpaceName)
            .onPreferenceChange(SlotFramePreferenceKey.self) { frames in
                slotFrames = frames
            }
            .navigationTitle(ChildNameSettings.possessive("칭찬판"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("알림", isPresented: $showQuotaAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(quotaAlertMessage)
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            Text("스티커 \(stickerStore.filledCount) / \(StickerStore.boardCount)")
                .font(.headline)
                .foregroundStyle(Color(hex: "FF6B8A"))
            ProgressView(value: Double(stickerStore.filledCount), total: Double(StickerStore.boardCount))
                .tint(Color(hex: "FF6B8A"))
                .padding(.horizontal, 32)

            if stickerStore.canOpenWheel {
                Button {
                    showWheel = true
                } label: {
                    Label(
                        stickerStore.wheelSpun ? "돌림판 확인하기" : "돌림판 돌리기",
                        systemImage: "gift.fill"
                    )
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
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
    }

    private var quotaSection: some View {
        VStack(spacing: 8) {
            Button {
                quotaInput = ""
                quotaPassword = ""
                showQuotaPanel = true
            } label: {
                Text("칭찬스티커 붙이기")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B8A"), Color(hex: "FF8FAB")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .padding(.horizontal, 24)

            Text("붙일 수 있는 스티커: \(stickerStore.stickerQuotaRemaining)개")
                .font(.subheadline.bold())
                .foregroundStyle(Color(hex: "FF6B8A"))
        }
    }

    private var quotaOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showQuotaPanel = false }

            VStack(spacing: 16) {
                Text("칭찬스티커 붙이기")
                    .font(.headline.bold())
                    .foregroundStyle(Color(hex: "FF6B8A"))

                Text("붙일 수 있는 스티커 개수와\n엄마 비밀번호를 입력해 주세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("개수", text: $quotaInput)
                    .keyboardType(.numberPad)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )

                SecureField("엄마 비밀번호", text: $quotaPassword)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )

                HStack(spacing: 12) {
                    Button("취소") {
                        showQuotaPanel = false
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 2)
                    )

                    Button("확인") {
                        confirmQuota()
                    }
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(quotaConfirmColor)
                    )
                    .disabled(!isQuotaInputValid)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 32)
        }
    }

    private var scatteredStickerBoard: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFF5F8"),
                                Color(hex: "FFE8F0"),
                                Color(hex: "FFD6E5"),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "FFB8D0"), lineWidth: 3)
                    )

                HeartBoardBackground()
                    .scaleEffect(min(geo.size.width / 200, geo.size.height / 220) * 0.95)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.48)

                ForEach(0..<StickerStore.boardCount, id: \.self) { index in
                    let layout = slotLayout[index]
                    stickerSlot(index: index)
                        .position(
                            x: geo.size.width * layout.x,
                            y: geo.size.height * layout.y
                        )
                        .rotationEffect(.degrees(layout.rotate))
                }
            }
        }
        .frame(height: 340)
        .frame(maxWidth: .infinity)
        .opacity(stickerStore.canPlace ? 1 : 0.75)
    }

    private func stickerSlot(index: Int) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(stickerStore.sticker(for: index) != nil ? 0.95 : 0.88))
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .stroke(
                            stickerStore.sticker(for: index) != nil
                                ? Color(hex: "FF6B8A")
                                : Color(hex: "FF8FAB").opacity(0.55),
                            style: stickerStore.sticker(for: index) != nil
                                ? StrokeStyle(lineWidth: 2)
                                : StrokeStyle(lineWidth: 2, dash: [5, 4])
                        )
                )
                .shadow(color: Color(hex: "FF6B8A").opacity(0.12), radius: 3, y: 2)

            if let placed = stickerStore.sticker(for: index) {
                Text(placed)
                    .font(.system(size: 28))
                    .allowsHitTesting(false)
            } else {
                Image(systemName: "plus")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "FF6B8A").opacity(0.65))
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: SlotFramePreferenceKey.self,
                    value: [index: proxy.frame(in: .named(stickerSpaceName))]
                )
            }
        )
        .onTapGesture {
            guard stickerStore.canPlace, stickerStore.sticker(for: index) == nil else { return }
            if let sticker = selectedSticker {
                guard stickerStore.place(sticker: sticker, on: index) else { return }
                selectedSticker = nil
                checkCompletion()
            }
        }
        .dropDestination(for: String.self) { items, _ in
            guard stickerStore.canPlace else { return false }
            guard let sticker = items.first else { return false }
            guard stickerStore.place(sticker: sticker, on: index) else { return false }
            checkCompletion()
            return true
        } isTargeted: { _ in }
    }

    private func paletteItem(_ emoji: String) -> some View {
        let isSelected = selectedSticker == emoji
        return Text(emoji)
            .font(.system(size: 28))
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "FF6B8A").opacity(0.2) : Color.white)
                    .shadow(color: Color(hex: "FF6B8A").opacity(0.1), radius: 2, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color(hex: "FF6B8A") : Color.clear, lineWidth: 2)
            )
            .opacity(draggingSticker == emoji ? 0.4 : 1)
            .onTapGesture {
                selectedSticker = isSelected ? nil : emoji
            }
            .gesture(stickerDragGesture(emoji))
    }

    private func stickerDragGesture(_ emoji: String) -> some Gesture {
        DragGesture(coordinateSpace: .named(stickerSpaceName))
            .onChanged { value in
                guard stickerStore.canPlace else { return }
                draggingSticker = emoji
                dragLocation = value.location
            }
            .onEnded { value in
                guard draggingSticker != nil else { return }
                handleDrop(emoji, at: value.location)
            }
    }

    private var stickerPalette: some View {
        VStack(spacing: 8) {
            Text("스티커")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "FF6B8A"))

            ScrollView {
                LazyVGrid(columns: [GridItem(.fixed(44)), GridItem(.fixed(44))], spacing: 8) {
                    ForEach(StickerStore.palette, id: \.self) { emoji in
                        paletteItem(emoji)
                    }
                }
            }
        }
        .frame(width: 110)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFF5F8"), Color(hex: "FFE8F0")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "FFB8D0").opacity(0.45), lineWidth: 2)
                )
        )
        .opacity(stickerStore.canPlace ? 1 : 0.45)
        .allowsHitTesting(stickerStore.canPlace)
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(ChildNameSettings.celebrationPraise)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("🎉✨🎊")
                    .font(.largeTitle)
            }
        }
        .transition(.opacity)
    }

    private var wheelOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            GeometryReader { geo in
                let bottomInset = max(geo.safeAreaInsets.bottom, 16)
                let wheelBudget = geo.size.height - 48 - bottomInset

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button("나중에") {
                                showWheel = false
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(hex: "888888"))
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                        }

                        if stickerStore.wheelSpun {
                            wheelConfirmOnly
                        } else {
                            SpinWheelView(
                                availableHeight: wheelBudget,
                                onResult: handlePrize,
                                onConfirm: finishWheelAndReset
                            )
                        }
                    }
                    .padding(.bottom, bottomInset + 12)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FFF9F0"), Color.white],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: geo.size.width)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    private var wheelConfirmOnly: some View {
        VStack(spacing: 20) {
            Text("🎡")
                .font(.system(size: 40))
            Text("돌림판 보상을 받았어요!")
                .font(.title3.bold())
                .foregroundStyle(Color(hex: "FF6B8A"))
            Text("확인을 누르면 칭찬판이 새로 시작돼요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                finishWheelAndReset()
            } label: {
                Text("확인")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B8A"), Color(hex: "FF8FAB")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 8)
    }

    private var isQuotaInputValid: Bool {
        guard let count = Int(quotaInput.filter(\.isNumber)), count > 0 else { return false }
        return !quotaPassword.isEmpty
    }

    private var quotaConfirmColor: Color {
        isQuotaInputValid ? Color(hex: "4ECDC4") : Color(hex: "FF6B8A").opacity(0.45)
    }

    private func confirmQuota() {
        guard store.hasPassword else {
            quotaAlertMessage = "엄마가 관리에서 비밀번호를 먼저 만들어 주세요."
            showQuotaAlert = true
            return
        }
        guard store.verifyPassword(quotaPassword) else {
            quotaAlertMessage = "비밀번호가 틀렸어요."
            showQuotaAlert = true
            quotaPassword = ""
            return
        }
        guard let count = Int(quotaInput.filter(\.isNumber)), count > 0 else {
            quotaAlertMessage = "올바른 개수를 입력해 주세요."
            showQuotaAlert = true
            return
        }
        stickerStore.grantQuota(count)
        showQuotaPanel = false
        quotaPassword = ""
        HapticFeedback.success()
        quotaAlertMessage = "스티커 \(count)개를 붙일 수 있어요!"
        showQuotaAlert = true
    }

    private func finishWheelAndReset() {
        showWheel = false
        showFireworks = false
        if pendingSpendAnimation {
            onSpendJarPulse?()
            pendingSpendAnimation = false
        }
        stickerStore.finishWheelReward()
    }

    private func handleDrop(_ sticker: String, at point: CGPoint) {
        defer {
            withAnimation(.easeOut(duration: 0.15)) { draggingSticker = nil }
        }
        guard stickerStore.canPlace else { return }

        var nearest: (index: Int, distance: CGFloat)?
        for (index, frame) in slotFrames {
            guard stickerStore.sticker(for: index) == nil else { continue }
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let distance = hypot(center.x - point.x, center.y - point.y)
            if distance < (nearest?.distance ?? .greatestFiniteMagnitude) {
                nearest = (index, distance)
            }
        }

        guard let target = nearest, target.distance <= 44 else { return }
        guard stickerStore.place(sticker: sticker, on: target.index) else { return }
        selectedSticker = nil
        HapticFeedback.light()
        checkCompletion()
    }

    private func checkCompletion() {
        guard stickerStore.isComplete, !showCelebration else { return }
        stickerStore.markWheelRewardPending()
        withAnimation {
            showFireworks = true
            showCelebration = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showCelebration = false
            showWheel = true
        }
    }

    private func handlePrize(_ prize: WheelPrize) {
        stickerStore.markWheelSpun()
        if let amount = prize.spendAmount {
            store.deposit(to: .spend, amount: amount, kind: .wheel, note: "돌림판 당첨")
            pendingSpendAnimation = true
            showFireworks = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showFireworks = false }
        } else if prize.isToyStore {
            showFireworks = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showFireworks = false }
        }
    }
}

private extension Int {
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

private struct SlotFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

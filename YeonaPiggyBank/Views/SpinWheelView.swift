import SwiftUI

struct SpinWheelView: View {
    var availableHeight: CGFloat? = nil
    let onResult: (WheelPrize) -> Void
    let onConfirm: () -> Void

    @State private var rotation: Double = 0
    @State private var isSpinning = false
    @State private var selectedPrize: WheelPrize?
    @State private var hasFinished = false
    @State private var winningIndex: Int?
    @State private var winPulse = false
    @State private var sparklePhase = false
    @State private var layoutWidth: CGFloat = 390
    @State private var layoutHeight: CGFloat = 700

    private let prizes = WheelPrize.all
    private let sliceCount = WheelPrize.all.count
    private let pointerAngle: Double = -90

    private var sliceAngle: Double { 360.0 / Double(sliceCount) }

    private var sizingHeight: CGFloat {
        availableHeight ?? layoutHeight
    }

    private var wheelSize: CGFloat {
        LayoutMetrics.spinWheelSize(screenWidth: layoutWidth, availableHeight: sizingHeight)
    }

    private var contentSpacing: CGFloat {
        sizingHeight < 620 ? 10 : 14
    }

    var body: some View {
        VStack(spacing: contentSpacing) {
            header

            ZStack {
                wheelShadow
                wheelFrame
                rotatingWheel
                if hasFinished, selectedPrize != nil {
                    winSparkles
                }
                wheelPointer
            }
            .frame(width: wheelSize + 40, height: wheelSize + 44)

            resultArea
            actionButton
        }
        .padding(.top, sizingHeight < 620 ? 4 : 8)
        .padding(.bottom, 20)
        .trackSize(width: $layoutWidth, height: $layoutHeight)
        .onChange(of: hasFinished) { _, finished in
            guard finished else { return }
            winPulse = false
            sparklePhase = false
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                winPulse = true
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                sparklePhase = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: sizingHeight < 620 ? 4 : 6) {
            Text("🎡")
                .font(.system(size: sizingHeight < 620 ? 28 : 34))
            Text(ChildNameSettings.possessive("행운 돌림판"))
                .font(.system(size: sizingHeight < 620 ? 19 : 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "FF6B8A"))
            Text("버튼을 눌러 돌려 보세요!")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "888888"))
        }
    }

    // MARK: - Wheel layers

    private var wheelShadow: some View {
        Circle()
            .fill(Color.black.opacity(0.12))
            .frame(width: wheelSize + 8, height: wheelSize + 8)
            .offset(y: 6)
            .blur(radius: 4)
    }

    private var wheelFrame: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFE566"), Color(hex: "FFB300"), Color(hex: "E8940A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: wheelSize + 20, height: wheelSize + 20)

            Circle()
                .stroke(Color.white.opacity(0.55), lineWidth: 2)
                .frame(width: wheelSize + 14, height: wheelSize + 14)

            Circle()
                .fill(Color(hex: "FFF8E1"))
                .frame(width: wheelSize + 6, height: wheelSize + 6)
        }
    }

    private var rotatingWheel: some View {
        ZStack {
            ForEach(Array(prizes.enumerated()), id: \.element.id) { index, prize in
                WheelPieSlice(
                    startDegrees: sliceAngle * Double(index) + pointerAngle,
                    sweepDegrees: sliceAngle,
                    colors: prize.sliceColors
                )
                .frame(width: wheelSize, height: wheelSize)
            }

            if let winningIndex, hasFinished {
                WheelPieSlice(
                    startDegrees: sliceAngle * Double(winningIndex) + pointerAngle,
                    sweepDegrees: sliceAngle,
                    colors: (Color.white.opacity(0.5), Color.white.opacity(0.2), Color.white.opacity(0.8))
                )
                .frame(width: wheelSize, height: wheelSize)
                .opacity(winPulse ? 0.85 : 0.35)
            }

            ForEach(Array(prizes.enumerated()), id: \.element.id) { index, prize in
                segmentLabel(for: prize, index: index, highlighted: winningIndex == index && hasFinished)
            }

            wheelHub
        }
        .frame(width: wheelSize, height: wheelSize)
        .rotationEffect(.degrees(rotation))
    }

    private var winSparkles: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Text("✨")
                    .font(.system(size: sparklePhase ? 18 : 12))
                    .opacity(sparklePhase ? 1 : 0.45)
                    .offset(y: -(wheelSize / 2 + 22))
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
        .allowsHitTesting(false)
    }

    private func segmentLabel(for prize: WheelPrize, index: Int, highlighted: Bool) -> some View {
        let midAngle = sliceAngle * (Double(index) + 0.5) + pointerAngle
        let radians = midAngle * .pi / 180
        let labelRadius = wheelSize * 0.30
        let emojiSize = wheelSize * 0.10

        return VStack(spacing: 3) {
            prizeEmojiView(for: prize, size: emojiSize, highlighted: highlighted)

            Text(prize.shortLabel)
                .font(.system(size: max(10, wheelSize * 0.043), weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(highlighted ? Color.white.opacity(0.35) : Color.black.opacity(0.22))
                        .overlay(Capsule().stroke(Color.white.opacity(highlighted ? 0.7 : 0.35), lineWidth: highlighted ? 1.2 : 0.8))
                )
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .rotationEffect(.degrees(midAngle + 90))
        .offset(x: cos(radians) * labelRadius, y: sin(radians) * labelRadius)
    }

    @ViewBuilder
    private func prizeEmojiView(for prize: WheelPrize, size: CGFloat, highlighted: Bool) -> some View {
        if let count = prize.moneyBagCount {
            HStack(spacing: size * -0.22) {
                ForEach(0..<count, id: \.self) { _ in
                    Text("💰")
                        .font(.system(size: size))
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
            .scaleEffect(highlighted && winPulse ? 1.12 : 1)
        } else {
            Text(prize.wheelEmoji)
                .font(.system(size: size))
                .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                .scaleEffect(highlighted && winPulse ? 1.12 : 1)
        }
    }

    private var wheelHub: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color(hex: "FFF3E0")],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: wheelSize * 0.186, height: wheelSize * 0.186)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FF8C42")],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 4
                )
                .frame(width: wheelSize * 0.186, height: wheelSize * 0.186)

            Text(hasFinished ? "🎉" : "✨")
                .font(.system(size: wheelSize * 0.079))
        }
    }

    private var wheelPointer: some View {
        VStack(spacing: 0) {
            ZStack {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: wheelSize * 0.107, weight: .bold))
                    .foregroundStyle(Color(hex: "E8940A"))
                    .offset(y: 1)
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: wheelSize * 0.093, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF6B8A"), Color(hex: "FF8FA8")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: Color(hex: "FF6B8A").opacity(hasFinished ? 0.65 : 0.4), radius: hasFinished ? 8 : 4, y: 2)
            .scaleEffect(hasFinished && winPulse ? 1.08 : 1)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "E8940A"))
                .frame(width: 5, height: 12)
        }
        .offset(y: -(wheelSize / 2 + 14))
    }

    // MARK: - Result & action

    @ViewBuilder
    private var resultArea: some View {
        if let selectedPrize {
            VStack(spacing: 4) {
                HStack(spacing: 10) {
                    prizeEmojiView(for: selectedPrize, size: 28, highlighted: false)
                    Text(selectedPrize.resultTitle)
                        .font(.title3.bold())
                        .foregroundStyle(selectedPrize.color)
                }
                if selectedPrize.id == "blank" {
                    Text("괜찮아, 다음에 더 잘할 수 있어!")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "888888"))
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(selectedPrize.color.opacity(0.12))
                    .overlay(Capsule().stroke(selectedPrize.color.opacity(0.35), lineWidth: 1.5))
            )
            .transition(.scale.combined(with: .opacity))
        } else {
            Text(isSpinning ? "두근두근… 🍀" : "어떤 보상이 나올까요?")
                .font(.subheadline.bold())
                .foregroundStyle(Color(hex: "888888"))
                .frame(height: 44)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if hasFinished {
            Button {
                HapticFeedback.light()
                onConfirm()
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
        } else {
            Button(action: spin) {
                HStack(spacing: 8) {
                    if isSpinning {
                        ProgressView().tint(.white)
                    }
                    Text(isSpinning ? "돌아가는 중…" : "돌려!")
                }
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSpinning
                                ? LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(
                                    colors: [Color(hex: "FFB347"), Color(hex: "FF6B8A")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .shadow(color: isSpinning ? .clear : Color(hex: "FF6B8A").opacity(0.35), radius: 8, y: 4)
                )
            }
            .disabled(isSpinning)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Spin logic

    private func segmentMidAngle(_ index: Int) -> Double {
        sliceAngle * (Double(index) + 0.5) + pointerAngle
    }

    private func targetRotation(from start: Double, for index: Int) -> Double {
        let mid = segmentMidAngle(index)
        var delta = pointerAngle - mid - start
        while delta <= 0 { delta += 360 }
        return start + delta + 360 * 6
    }

    private func spin() {
        guard !isSpinning, !hasFinished else { return }
        isSpinning = true
        selectedPrize = nil
        winningIndex = nil
        winPulse = false
        sparklePhase = false

        let winIndex = Int.random(in: 0..<prizes.count)
        let target = targetRotation(from: rotation, for: winIndex)
        HapticFeedback.medium()

        withAnimation(.timingCurve(0.12, 0.85, 0.15, 1.0, duration: 4.2)) {
            rotation = target
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            let landed = prizes[winIndex]
            winningIndex = winIndex
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                selectedPrize = landed
            }
            isSpinning = false
            hasFinished = true
            HapticFeedback.success()
            onResult(landed)
        }
    }
}

// MARK: - Pie slice

private struct WheelPieSlice: View {
    let startDegrees: Double
    let sweepDegrees: Double
    let colors: (top: Color, bottom: Color, stroke: Color)

    var body: some View {
        WheelPieSliceShape(startDegrees: startDegrees, sweepDegrees: sweepDegrees)
            .fill(
                AngularGradient(
                    colors: [colors.top, colors.bottom, colors.top],
                    center: .center,
                    startAngle: .degrees(startDegrees),
                    endAngle: .degrees(startDegrees + sweepDegrees)
                )
            )
            .overlay(
                WheelPieSliceShape(startDegrees: startDegrees, sweepDegrees: sweepDegrees)
                    .stroke(colors.stroke, lineWidth: 1.5)
            )
    }
}

private struct WheelPieSliceShape: Shape {
    let startDegrees: Double
    let sweepDegrees: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startDegrees),
            endAngle: .degrees(startDegrees + sweepDegrees),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

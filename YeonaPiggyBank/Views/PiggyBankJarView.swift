import SwiftUI

enum PiggyBankJarStyle {
    case card
    case modal
}

struct PiggyBankJarView: View {
    let bank: PiggyBank
    var style: PiggyBankJarStyle = .card
    var cardWidth: CGFloat = 200
    var animateOnBalanceChange: Bool = false
    var externalPulseToken: Int = 0
    var saveBonusRatePercent: Int = SaveBonusSettings.defaultRate

    @State private var isPulsing = false

    private var accentColor: Color {
        Color(hex: bank.type.colorHex)
    }

    private var scale: CGFloat { cardWidth / 200 }

    private var isPhoneCard: Bool {
        DeviceLayout.isPhone && style == .card
    }

    private var isPadCard: Bool {
        DeviceLayout.isPad && style == .card
    }

    private var cardPadding: CGFloat {
        isPhoneCard ? max(8, 9 * scale) : 14 * scale
    }

    private var jarWidth: CGFloat {
        if isPhoneCard {
            let inner = cardWidth - cardPadding * 2
            return inner * 0.96
        }
        return 150 * scale
    }

    private var jarHeight: CGFloat {
        if isPhoneCard {
            return jarWidth * 0.94
        }
        return 147 * scale
    }

    private var jarCornerRadius: CGFloat {
        isPhoneCard ? jarWidth * 0.14 : 24 * scale
    }

    private var emojiSize: CGFloat {
        if isPhoneCard {
            return jarWidth * 0.30
        }
        return 32 * scale
    }

    private var cardCornerRadius: CGFloat { 28 * scale }
    private var saveInfoHeight: CGFloat { isPhoneCard ? 44 * scale : 48 * scale }
    private var cardContentSpacing: CGFloat { isPhoneCard ? 8 * scale : 11 * scale }

    private var nameFont: Font {
        if scale >= 1.15 { return .title.bold() }
        if scale < 0.9 { return .title3.bold() }
        return .title2.bold()
    }

    private var subtitleFont: Font {
        if scale >= 1.15 { return .body }
        if scale < 0.9 { return .caption }
        return .subheadline
    }

    private var balanceFont: Font {
        if scale >= 1.15 { return .title3.bold() }
        if scale < 0.9 { return .subheadline.bold() }
        return .headline
    }

    var body: some View {
        switch style {
        case .card:
            cardBody
        case .modal:
            jarGraphic
                .padding(.vertical, 4)
        }
    }

    private var cardBody: some View {
        VStack(spacing: cardContentSpacing) {
            jarGraphic

            VStack(spacing: isPhoneCard ? 3 * scale : 4 * scale) {
                Text(bank.type.name)
                    .font(nameFont)
                    .foregroundStyle(AppTheme.jarTitleText)

                Text(bank.type.subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(AppTheme.subtitleText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)

                Text(bank.formattedBalance)
                    .font(balanceFont)
                    .foregroundStyle(accentColor)
                    .padding(.top, isPhoneCard ? 2 : 4)
                    .scaleEffect(isPulsing ? 1.1 : 1)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPulsing)
                    .contentTransition(.numericText())

                if bank.type == .save {
                    SaveCountdownView(compact: true, bonusRatePercent: saveBonusRatePercent)
                        .frame(height: saveInfoHeight)
                } else if isPadCard {
                    Color.clear
                        .frame(height: saveInfoHeight)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: cardWidth)
        .padding(cardPadding)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(AppTheme.cardBackground)
                .shadow(color: accentColor.opacity(0.2), radius: 12 * scale, y: 6 * scale)
        )
        .fixedSize(horizontal: false, vertical: true)
    }

    private var jarGraphic: some View {
        ZStack {
            RoundedRectangle(cornerRadius: jarCornerRadius)
                .fill(AppTheme.cardBackground.opacity(0.9))
                .frame(width: jarWidth, height: jarHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: jarCornerRadius)
                        .stroke(accentColor.opacity(0.4), lineWidth: max(2, 3 * scale))
                )

            GeometryReader { geo in
                let fillHeight = geo.size.height * bank.fillRatio
                RoundedRectangle(cornerRadius: jarCornerRadius - 4)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.7), accentColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: max(fillHeight, bank.balance > 0 ? geo.size.height * 0.12 : 0))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(4 * scale)
                    .brightness(isPulsing ? 0.12 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.68), value: bank.fillRatio)
                    .animation(.easeOut(duration: 0.35), value: isPulsing)
            }
            .frame(width: jarWidth, height: jarHeight)

            if bank.fillRatio < 0.35 {
                Text(bank.type.emoji)
                    .font(.system(size: emojiSize * 2.0))
                    .opacity(isPhoneCard ? 0.14 : 0.10)
            }

            Text(bank.type.emoji)
                .font(.system(size: emojiSize))
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                .scaleEffect(isPulsing ? 1.12 : 1)
                .animation(.spring(response: 0.45, dampingFraction: 0.55), value: isPulsing)
        }
        .frame(width: jarWidth, height: jarHeight)
        .scaleEffect(isPulsing ? 1.06 : 1)
        .animation(.spring(response: 0.45, dampingFraction: 0.62), value: isPulsing)
        .onChange(of: bank.balance) { _, _ in
            if animateOnBalanceChange { triggerPulse() }
        }
        .onChange(of: externalPulseToken) { _, _ in
            triggerPulse()
        }
    }

    private func triggerPulse() {
        isPulsing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            isPulsing = false
        }
    }
}

struct SaveCountdownView: View {
    var compact: Bool = false
    var bonusRatePercent: Int = SaveBonusSettings.defaultRate

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let canWithdraw = MonthEndHelper.canWithdrawSave(from: context.date)
            VStack(spacing: compact ? 2 : 4) {
                Text("오늘의 투자 수익까지")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(SaveInterestHelper.formattedCountdownToPayout(from: context.date))
                    .font(compact ? .caption.bold() : .caption.bold())
                    .foregroundStyle(Color(hex: "4ECDC4"))
                    .monospacedDigit()

                if compact {
                    Text("월 \(bonusRatePercent)% · 매일 밤 9시 · 출금 1~5일")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                } else {
                    Text("저축 잔액에 월 \(bonusRatePercent)% 이율로\n매일 밤 9시에 하루치 수익이 붙어요")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                    Text(canWithdraw
                         ? "지금 저축→용돈 출금 가능 (1~5일)"
                         : "저축 출금은 매월 1~5일만 가능해요")
                        .font(.caption2.bold())
                        .foregroundStyle(canWithdraw ? Color(hex: "4ECDC4") : Color(hex: "FF8C42"))
                        .multilineTextAlignment(.center)
                    Text("저축에서 출금하면 용돈으로 이동해요")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.top, compact ? 4 : 6)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

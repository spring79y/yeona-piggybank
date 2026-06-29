import SwiftUI

struct WheelPrizeIcon: View {
    let prizeId: String
    var compact: Bool = false

    var body: some View {
        Group {
            if compact {
                compactIcon
            } else {
                fullIcon
            }
        }
        .frame(width: compact ? 30 : 40, height: compact ? 30 : 40)
    }

    @ViewBuilder
    private var fullIcon: some View {
        switch prizeId {
        case "1000": coinOneIcon
        case "2000": coinTwoIcon
        case "3000": coinThreeIcon
        case "toys": toyStoreIcon
        default: blankIcon
        }
    }

    @ViewBuilder
    private var compactIcon: some View {
        switch prizeId {
        case "1000": compactCoinOne
        case "2000": compactCoinTwo
        case "3000": compactCoinThree
        case "toys": compactToyStore
        default: compactBlank
        }
    }

    private var compactCoinOne: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFD700"))
                .overlay(Circle().stroke(Color(hex: "E8940A"), lineWidth: 1.5))
            Circle()
                .fill(Color(hex: "FFE566"))
                .padding(5)
            Text("1")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "C27800"))
        }
    }

    private var compactCoinTwo: some View {
        HStack(spacing: -4) {
            compactMiniCoin(label: "2")
            compactMiniCoin(label: "2")
        }
    }

    private var compactCoinThree: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFD700"))
                .overlay(Circle().stroke(Color(hex: "E8940A"), lineWidth: 1.5))
            Text("3")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "C27800"))
        }
    }

    private func compactMiniCoin(label: String) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(Color(hex: "E8940A"), lineWidth: 1))
            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(Color(hex: "C27800"))
        }
    }

    private var compactToyStore: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "E31837"))
                .frame(width: 26, height: 14)
                .offset(y: -4)
            RoundedRectangle(cornerRadius: 2)
                .fill(.white)
                .frame(width: 24, height: 12)
                .offset(y: 5)
            Text("🧸")
                .font(.system(size: 14))
        }
    }

    private var compactBlank: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "ECEFF1"))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: "90A4AE"), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
                )
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "78909C"))
        }
    }

    private var coinOneIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: 36, height: 36)
                .overlay(Circle().stroke(Color(hex: "E8940A"), lineWidth: 2))
            Circle()
                .fill(Color(hex: "FFE566"))
                .frame(width: 28, height: 28)
            Text("1")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "C27800"))
            Text("₩")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color(hex: "E8940A"))
                .offset(y: -14)
        }
    }

    private var coinTwoIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color(hex: "E8940A"), lineWidth: 1.5))
                .offset(x: -10, y: 4)
            Text("2")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Color(hex: "C27800"))
                .offset(x: -10, y: 4)
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color(hex: "E8940A"), lineWidth: 1.5))
                .offset(x: 10, y: -2)
            Text("2")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Color(hex: "C27800"))
                .offset(x: 10, y: -2)
            Text("2천")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(Color(hex: "FF8C42"))
                .offset(y: -16)
        }
    }

    private var coinThreeIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: 22, height: 22)
                .offset(x: -12, y: 6)
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(Color(hex: "E8940A"), lineWidth: 1.5))
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: 22, height: 22)
                .offset(x: 12, y: 6)
            Text("3")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Color(hex: "C27800"))
            Image(systemName: "star.fill")
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "4ECDC4"))
                .offset(y: -16)
        }
    }

    private var toyStoreIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(.white)
                .frame(width: 34, height: 20)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: "0054A6"), lineWidth: 1.5))
                .offset(y: 6)
            Path { path in
                path.move(to: CGPoint(x: 3, y: 14))
                path.addLine(to: CGPoint(x: 20, y: 2))
                path.addLine(to: CGPoint(x: 37, y: 14))
                path.closeSubpath()
            }
            .fill(Color(hex: "E31837"))
            .frame(width: 34, height: 14)
            .offset(y: -4)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "E8F4FF"))
                .frame(width: 12, height: 10)
                .overlay(RoundedRectangle(cornerRadius: 1).stroke(Color(hex: "0054A6"), lineWidth: 0.8))
                .offset(x: -8, y: 6)
            Circle()
                .fill(Color(hex: "FFB347"))
                .frame(width: 6, height: 6)
                .offset(x: -8, y: 6)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "9B59B6"))
                .frame(width: 8, height: 8)
                .offset(x: 8, y: 4)
            Text("TOYS")
                .font(.system(size: 4, weight: .bold))
                .foregroundStyle(.white)
                .offset(x: 8, y: 12)
            Image(systemName: "star.fill")
                .font(.system(size: 7))
                .foregroundStyle(Color(hex: "FFD700"))
                .offset(x: 14, y: -14)
        }
    }

    private var blankIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(hex: "90A4AE"), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .background(RoundedRectangle(cornerRadius: 3).fill(Color(hex: "ECEFF1")))
                .frame(width: 30, height: 24)
            Path { path in
                path.move(to: CGPoint(x: 10, y: 12))
                path.addLine(to: CGPoint(x: 20, y: 22))
                path.move(to: CGPoint(x: 20, y: 12))
                path.addLine(to: CGPoint(x: 10, y: 22))
            }
            .stroke(Color(hex: "78909C"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            Text("X")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color(hex: "78909C"))
                .offset(y: 16)
        }
    }
}

struct WheelCenterCoinIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color(hex: "E8940A"), lineWidth: 1.5))
            Circle()
                .fill(Color(hex: "FFE566"))
                .frame(width: 22, height: 22)
            Text("₩")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Color(hex: "C27800"))
        }
    }
}

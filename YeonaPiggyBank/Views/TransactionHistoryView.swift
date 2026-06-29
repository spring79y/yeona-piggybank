import SwiftUI

struct TransactionHistoryView: View {
    @ObservedObject var store: PiggyBankStore
    let type: PiggyBankType
    @Environment(\.dismiss) private var dismiss

    @State private var monthRange = 1

    private var accentColor: Color {
        Color(hex: type.colorHex)
    }

    private var allEntries: [PiggyBankTransaction] {
        store.history(for: type)
    }

    private var filteredEntries: [PiggyBankTransaction] {
        guard let start = HistoryMonthHelper.rangeStart(monthCount: monthRange) else {
            return allEntries
        }
        return allEntries.filter { $0.date >= start }
    }

    private var groupedEntries: [(label: String, items: [PiggyBankTransaction])] {
        HistoryMonthHelper.groupByMonth(filteredEntries)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("기간", selection: $monthRange) {
                    Text("1개월").tag(1)
                    Text("2개월").tag(2)
                    Text("3개월").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                Group {
                    if allEntries.isEmpty {
                        ContentUnavailableView {
                            Label("아직 이력이 없어요", systemImage: "tray")
                        } description: {
                            Text("입금·출금하면 여기에 기록돼요")
                        }
                    } else if filteredEntries.isEmpty {
                        ContentUnavailableView {
                            Label("이력이 없어요", systemImage: "calendar")
                        } description: {
                            Text("최근 \(monthRange)개월 이력이 없어요")
                        }
                    } else {
                        List {
                            ForEach(groupedEntries, id: \.label) { group in
                                Section(group.label) {
                                    ForEach(group.items) { entry in
                                        HistoryRow(entry: entry, accentColor: accentColor)
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("\(type.name) 이력")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .background(
                LinearGradient(
                    colors: [accentColor.opacity(0.06), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

enum HistoryMonthHelper {
    static func rangeStart(monthCount: Int, from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let currentMonthStart = calendar.date(from: components) else { return nil }
        return calendar.date(byAdding: .month, value: -(monthCount - 1), to: currentMonthStart)
    }

    static func groupByMonth(_ entries: [PiggyBankTransaction]) -> [(label: String, items: [PiggyBankTransaction])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"

        var grouped: [String: [PiggyBankTransaction]] = [:]
        var order: [String] = []

        for entry in entries {
            let key = formatter.string(from: entry.date)
            if grouped[key] == nil {
                grouped[key] = []
                order.append(key)
            }
            grouped[key]?.append(entry)
        }

        return order.map { key in
            (label: key, items: grouped[key] ?? [])
        }
    }
}

private struct HistoryRow: View {
    let entry: PiggyBankTransaction
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.kind.label)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(entry.kind.isCredit ? accentColor : Color.orange)
                    )

                Spacer()

                Text(entry.signedAmountText)
                    .font(.headline.bold())
                    .foregroundStyle(entry.kind.isCredit ? accentColor : Color.orange)
            }

            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("잔액 \(entry.balanceAfter.formatted)원")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.vertical, 4)
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

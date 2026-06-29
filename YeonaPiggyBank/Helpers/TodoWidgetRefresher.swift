import WidgetKit

enum TodoWidgetRefresher {
    static let kind = "TodoWidget"

    static func reload() {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}

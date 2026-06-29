import Foundation
import UserNotifications

enum TodoReminderScheduler {
    static let reminderHours = [17, 18, 19, 20]
    static var message: String { ChildNameSettings.todoReminder }
    static let enabledKey = "yeona_todo_reminder_enabled"

    static var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: enabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: enabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
        }
    }

    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: enabledKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: notificationIds()
        )
    }

    static func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    @MainActor
    static func reschedule(todoStore: TodoStore) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: notificationIds())

        guard isEnabled else { return }
        guard todoStore.hasPublishedSchedule() else { return }
        guard !todoStore.allComplete() else { return }
        guard TodoCycleHelper.isActivePeriod() else { return }

        let visible = todoStore.visibleItems()
        guard !visible.isEmpty, visible.contains(where: { !$0.completed }) else { return }

        let calendar = Calendar.current
        let now = Date()

        for hour in reminderHours {
            guard hour < TodoCycleHelper.deadlineHour else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = hour
            components.minute = 0
            components.second = 0
            guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = ChildNameSettings.appTitle
            content.body = message
            content.sound = .default

            let triggerComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "todo_reminder_\(hour)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    static func notificationIds() -> [String] {
        reminderHours.map { "todo_reminder_\($0)" }
    }
}

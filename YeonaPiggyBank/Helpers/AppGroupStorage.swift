import Foundation

enum AppGroupStorage {
    static let suiteName = "group.com.yeona.piggybank"
    static let todoStorageKey = "yeona_todo_list"
    private static let todoFileName = "todo_state.json"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    private static var todoFileURL: URL? {
        containerURL?.appendingPathComponent(todoFileName)
    }

    static func migrateTodoDataIfNeeded() {
        guard todoData() == nil else { return }

        if let shared = sharedDefaults?.data(forKey: todoStorageKey), !shared.isEmpty {
            setTodoData(shared)
            return
        }

        if let legacy = UserDefaults.standard.data(forKey: todoStorageKey), !legacy.isEmpty {
            setTodoData(legacy)
        }
    }

    static func todoData() -> Data? {
        if let url = todoFileURL,
           let data = try? Data(contentsOf: url),
           !data.isEmpty {
            return data
        }

        if let shared = sharedDefaults?.data(forKey: todoStorageKey), !shared.isEmpty {
            return shared
        }

        if let legacy = UserDefaults.standard.data(forKey: todoStorageKey), !legacy.isEmpty {
            return legacy
        }

        return nil
    }

    static func setTodoData(_ data: Data) {
        if let url = todoFileURL {
            try? data.write(to: url, options: [.atomic])
        }
        if let shared = sharedDefaults {
            shared.set(data, forKey: todoStorageKey)
        }
        UserDefaults.standard.set(data, forKey: todoStorageKey)
    }

    static func loadTodoState() -> TodoState {
        migrateTodoDataIfNeeded()
        if let data = todoData(),
           let saved = try? JSONDecoder().decode(TodoState.self, from: data) {
            return saved
        }

        if let legacy = todoData() ?? UserDefaults.standard.data(forKey: todoStorageKey),
           let json = try? JSONSerialization.jsonObject(with: legacy) as? [String: Any],
           json["weekday"] == nil,
           let items = json["items"] as? [[String: Any]] {
            let migrated = items.compactMap { dict -> TodoItem? in
                guard let text = dict["text"] as? String else { return nil }
                let id = dict["id"] as? String ?? UUID().uuidString
                let completed = dict["completed"] as? Bool ?? false
                return TodoItem(id: id, text: text, completed: completed, pendingApproval: false)
            }
            let state = TodoState(
                resetDateKey: TodoCycleHelper.cycleDateKey(),
                weekday: TodoSchedule(
                    items: migrated,
                    published: json["published"] as? Bool ?? false,
                    rewardClaimed: json["rewardClaimed"] as? Bool ?? false
                ),
                weekend: TodoSchedule()
            )
            if let data = try? JSONEncoder().encode(state) {
                setTodoData(data)
            }
            return state
        }

        return TodoState(
            resetDateKey: TodoCycleHelper.cycleDateKey(),
            weekday: TodoSchedule(),
            weekend: TodoSchedule()
        )
    }
}

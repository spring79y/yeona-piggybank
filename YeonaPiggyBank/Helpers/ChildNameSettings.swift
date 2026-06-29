import Foundation

enum ChildNameSettings {
    static let lastNameKey = "yeona_child_last_name"
    static let firstNameKey = "yeona_child_first_name"

    static var lastName: String {
        read(lastNameKey)
    }

    static var firstName: String {
        read(firstNameKey)
    }

    static var hasName: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static var appTitle: String {
        hasName ? "\(firstName)의 저금통" : "내 아이의 저금통"
    }

    static func possessive(_ noun: String) -> String {
        hasName ? "\(firstName)의 \(noun)" : "내 아이의 \(noun)"
    }

    static var celebrationPraise: String {
        hasName ? "\(firstName)야~ 잘했어~!" : "잘했어~!"
    }

    static var todoReminder: String {
        hasName ? "\(firstName)야 할거 다 했어~~??" : "할거 다 했어~~??"
    }

    static var nightSuccess: String {
        hasName
            ? "오늘 해야 할 일을 모두 잘 해냈구나~ 칭찬해 \(firstName)야~"
            : "오늘 해야 할 일을 모두 잘 해냈구나~ 정말 잘했어~"
    }

    static var nightEncourage: String {
        hasName
            ? "\(firstName)야~ 아쉽지만 내일부터는 해야할 일을 꼭 해내자~ 화이팅~"
            : "아쉽지만 내일부터는 해야할 일을 꼭 해내자~ 화이팅~"
    }

    static var graffitiCheer: String {
        hasName ? "\(firstName) 화이팅!" : "화이팅!"
    }

    static var graffitiName: String? {
        hasName ? firstName : nil
    }

    static func save(lastName: String, firstName: String) {
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        write(lastNameKey, last)
        write(firstNameKey, first)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: lastNameKey)
        UserDefaults.standard.removeObject(forKey: firstNameKey)
        AppGroupStorage.sharedDefaults?.removeObject(forKey: lastNameKey)
        AppGroupStorage.sharedDefaults?.removeObject(forKey: firstNameKey)
    }

    private static func read(_ key: String) -> String {
        if let shared = AppGroupStorage.sharedDefaults?.string(forKey: key) {
            return shared
        }
        return UserDefaults.standard.string(forKey: key) ?? ""
    }

    private static func write(_ key: String, _ value: String) {
        UserDefaults.standard.set(value, forKey: key)
        AppGroupStorage.sharedDefaults?.set(value, forKey: key)
    }
}

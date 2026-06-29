import Foundation

enum OnboardingSettings {
    private static let completedKey = "yeona_onboarding_completed"

    static var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: completedKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: completedKey)
    }
}

import SwiftUI
import UIKit

@main
struct YeonaPiggyBankApp: App {
    @State private var scrollToTodo = false

    init() {
        // 스크롤뷰 안의 버튼·입력 필드가 첫 터치에 바로 반응하도록 (두 번 터치 방지)
        UIScrollView.appearance().delaysContentTouches = false
    }

    var body: some Scene {
        WindowGroup {
            MainView(scrollToTodo: $scrollToTodo)
                .onOpenURL { url in
                    guard url.scheme == "yeonapiggybank", url.host == "todo" else { return }
                    scrollToTodo = true
                }
        }
    }
}

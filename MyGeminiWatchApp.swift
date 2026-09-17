import SwiftUI

@main
struct MyGeminiWatchApp: App {
    @StateObject private var chatStore = ChatStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatStore)
        }
    }
}

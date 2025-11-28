import SwiftUI

@main
struct InterviewBuddyApp: App {
    @State private var immersionStyle: ImmersionStyle = .mixed  // ← 提升到 App

    var body: some Scene {
        WindowGroup {
            ContentView(immersionStyle: $immersionStyle)        // ← 傳給 ContentView
        }

        ImmersiveSpace(id: "InterviewSpace") {
            InterviewImmersiveView()
        }
        // ✅ 這個修飾器要掛在「Scene」上
        .immersionStyle(selection: $immersionStyle, in: .full)

    }
}

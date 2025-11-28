import SwiftUI
import RealityKit
import RealityKitContent  // ← 讓我們可以用 realityKitContentBundle

struct InterviewImmersiveView: View {
    var body: some View {
        RealityView { content in
            // 1) 從 RCP 內容包載入你剛剛做的場景（MeetingRoomScene）
            if let scene = try? await Entity(named: "MeetingRoomScene",
                                             in: realityKitContentBundle) {
                content.add(scene)

                // 2) 把「面試官」找出來，做基本調整
                if let interviewer = scene.findEntity(named: "Interviewer") {
                    let b = interviewer.visualBounds(recursive: true, relativeTo: scene)
                    let minY = b.min.y              // 角色最底部（相對 scene）
                    if minY != 0 {
                        // 把它往上/下平移，使最底部貼齊 scene 的 y=0（假設地板在 y=0）
                        interviewer.position.y -= minY
                    }
                }

            }
        }
    }
}
#Preview {
    InterviewImmersiveView()
}

import SwiftUI
import AVFAudio
import Speech

// 用於 UI 的枚舉（可 Hashable）
enum ImmersionChoice: String, CaseIterable, Hashable {
    case mixed, full

    var style: ImmersionStyle { .full }
}


struct ContentView: View {
    // 從 App 傳入真正的 ImmersionStyle（給 ImmersiveSpace 使用）
    @Binding var immersionStyle: ImmersionStyle

    // 本地 UI 狀態：用枚舉驅動 Picker
    @State private var choice: ImmersionChoice = .mixed

    @StateObject private var speech = SpeechManager()
    @State private var isSpeaking = false

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var didOpenSpace = false
    @State private var lastError: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("面試小幫手 🤖").font(.largeTitle)

            Text(speech.transcript.isEmpty ? "我在等你說話喔～" : speech.transcript)
                .padding()
                .frame(maxWidth: 600)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack {
                Button("開始講") {
                    Task { try? await speech.startListening() }
                }
                .buttonStyle(.borderedProminent)

                Button("停止") {
                    speech.stopListening()
                }
                .buttonStyle(.bordered)
            }

            Button(isSpeaking ? "停止說話" : "面試官說話") {
                if isSpeaking {
                    speech.stopSpeaking()
                    isSpeaking = false
                } else {
                    speech.say(text: "你好，我是面試官！請你先自我介紹一下。")
                    isSpeaking = true
                }
            }

            Divider().padding(.vertical, 8)

            HStack(spacing: 12) {
                Button(didOpenSpace ? "已在會議室" : "進入會議室") {
                    Task {
                        let result = await openImmersiveSpace(id: "InterviewSpace")
                        switch result {
                        case .opened:
                            didOpenSpace = true
                            lastError = nil
                        case .userCancelled, .error:   // 只有這三種
                            lastError = "開啟失敗或被取消"
                        @unknown default:
                            lastError = "未知狀況"
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(didOpenSpace)

                Button("離開會議室") {
                    Task {
                        await dismissImmersiveSpace()
                        didOpenSpace = false
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!didOpenSpace)
            }

            // 用枚舉做 Picker（Hashable OK）
            Picker("沉浸樣式", selection: $choice) {
                Text("Full").tag(ImmersionChoice.full)
            }
            .pickerStyle(.segmented)
        }
        .padding(40)
        // 當使用者切換 Picker，把值映射回真正的 ImmersionStyle
        .onChange(of: choice) { _, newValue in
            immersionStyle = newValue.style
        }
    }
}

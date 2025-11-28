import Foundation
import AVFoundation   // 讓 AVSpeechSynthesizer / AVSpeechUtterance 可用
import AVFAudio      // 讓 AVAudioEngine / AVAudioSession 可用
import Speech        // 讓 SFSpeechRecognizer 可用

@MainActor
final class SpeechManager: NSObject, ObservableObject {

    @Published var transcript: String = ""

    private let speaker = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func say(text: String) {
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        speaker.speak(u)
    }

    func startListening() async throws {
        try await requestPermissions()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .duckOthers])
        try session.setActive(true)

        let input = audioEngine.inputNode
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        task = recognizer?.recognitionTask(with: request!) { [weak self] result, error in
            if let t = result?.bestTranscription.formattedString { self?.transcript = t }
            if let error { print("Recognition error:", error.localizedDescription) }
        }

        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
    }

    func stopSpeaking() {
        speaker.stopSpeaking(at: .immediate)
    }

    private func requestPermissions() async throws {
        let srStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard srStatus == .authorized else { throw NSError(domain: "Speech", code: 1) }

        let micOK = await withCheckedContinuation { cont in
            if #available(visionOS 1.0, iOS 17.0, macOS 14.0, *) {
                // ✅ AVAudioApplication 的「類別方法」
                AVAudioApplication.requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
            } else {
                // 舊系統相容
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
            }
        }
        guard micOK else { throw NSError(domain: "Mic", code: 2) }
    }
}

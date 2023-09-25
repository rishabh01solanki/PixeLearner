import Foundation
import Speech

class SpeechToTextManager: NSObject, ObservableObject {
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer()
    
    @Published var recognizedText: String = ""
    @Published var isRecording = false

    func startRecording() {
        do {
            if isRecording { // If already recording, stop first
                stopRecording()
            }

            // Ensure any previous task is cancelled and audioEngine is reset
            if let recognitionTask = recognitionTask {
                recognitionTask.cancel()
                self.recognitionTask = nil
            }

            // Remove previous audio input tap if exists
            audioEngine.inputNode.removeTap(onBus: 0)

            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            let inputNode = audioEngine.inputNode

            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create request")
            }
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
                if let result = result {
                    self?.recognizedText = result.bestTranscription.formattedString
                }
            })
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isRecording = true
            recognizedText = ""  // Clear out the previous recognized text

        } catch {
            print("There was a problem starting the speech recognition: \(error)")
        }
    }

    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
}


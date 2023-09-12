import SwiftUI
import CoreML
import CoreImage
import UIKit

struct ContentView: View {
    @State private var isImagePickerPresented: Bool = false
    @State private var predictionLabel: String = "Please select an image"
    @State private var confidence: Float = 0.0
    @State private var isModelProcessing: Bool = false
    @State private var feedbackMessage: String = ""
    @State private var displayImage: UIImage?
    @State private var selectedImage: UIImage?
    @State private var modelUpdater = ModelUpdater()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                imageSection
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(20)

                predictionAndFeedbackDisplay

                if selectedImage != nil {
                    feedbackButtons
                        .padding(.top, 15)
                }

                Spacer()

                selectImageButton
            }
            .padding()
            .navigationBarTitle("Image Classifier", displayMode: .inline)
            .overlay(
                Group {
                    if isModelProcessing {
                        ProgressView() // A built-in spinner in SwiftUI
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(2, anchor: .center)
                    }
                }
            )
            .sheet(isPresented: $isImagePickerPresented, onDismiss: predictImage) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    var imageSection: some View {
        Group {
            if let uiImage = self.displayImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(15)
            } else {
                defaultImageViewContent()
            }
        }
    }

    private func defaultImageViewContent() -> some View {
        Image(systemName: "photo.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray)
            .frame(width: 200, height: 200)
    }

    var predictionAndFeedbackDisplay: some View {
        VStack(spacing: 15) {
            Text(predictionLabel)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            Text("Confidence: \(String(format: "%.2f", confidence))%")
                .font(.subheadline)
                .opacity(confidence > 0 ? 1 : 0)
            Text(feedbackMessage)
                .foregroundColor(.green)
                .opacity(feedbackMessage.isEmpty ? 0 : 1)
        }
        .padding(.horizontal)
    }

    var feedbackButtons: some View {
        HStack(spacing: 20) {
            feedbackButton(title: "Correct", color: .green) {
                updateUserFeedback(correct: true)
            }
            feedbackButton(title: "Incorrect", color: .red) {
                updateUserFeedback(correct: false)
            }
        }
    }

    var selectImageButton: some View {
        Button("Select Image") {
            isImagePickerPresented = true
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(15)
        .padding(.bottom)
    }

    func feedbackButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(title) {
            action()
        }
        .padding()
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(10)
    }

    enum Label: Int32 {
        case notRishabh = 0
        case isRishabh = 1
    }

    func updateUserFeedback(correct: Bool) {
        isModelProcessing = true

        guard let selectedImage = selectedImage,
              let pixelBuffer = buffer(from: selectedImage) else {
            print("Debug: Either selectedImage is nil or pixelBuffer conversion failed.")
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let faceObservations = detectFaces(in: ciImage)
        
        guard let largestFaceObservation = getLargestFace(in: faceObservations) else {
            print("Error detecting faces or retrieving largest face")
            return
        }
        
        let squareFaceBox = squareBoundingBox(from: largestFaceObservation, in: ciImage)
        let squareFaceImage = ciImage.cropped(to: squareFaceBox)
        
        guard let resizedPixelBuffer = resize(image: squareFaceImage, toSize: CGSize(width: 150, height: 150)) else {
            print("Debug: Image resizing failed.")
            return
        }
        
        guard let outputLabel = try? MLMultiArray(shape: [1], dataType: .int32) else {
            print("Debug: Failed to create MLMultiArray for label.")
            return
        }
        
        let isRishabh = predictionLabel == "Looks like Rishabh"
        let labelMapping: [Bool: [Bool: Int32]] = [
            true: [true: 1, false: 0],
            false: [true: 0, false: 1]
        ]
        
        if let label = labelMapping[isRishabh]?[correct] {
            outputLabel[0] = NSNumber(value: label)
        } else {
            print("Debug: Error in label mapping.")
            return
        }
        
        print("Feedback: \(correct ? "Correct" : "Incorrect"), Current Prediction: \(isRishabh ? "Looks like Rishabh" : "Doesn't look like Rishabh"), Feedback Label: \(outputLabel[0])")
        
        let trainingInput = cnnTrainingInput(conv2d_input: resizedPixelBuffer, output1_true: outputLabel)
        let batch = MLArrayBatchProvider(array: [trainingInput])
        
        modelUpdater.updateWith(trainingData: batch) {
            feedbackMessage = "Model updated based on your feedback!"
            isModelProcessing = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                feedbackMessage = ""
                print("Model updated")
            }
        }
    }

    func predictImage() {
        if let selectedImage = selectedImage,
           let pixelBuffer = buffer(from: selectedImage) {
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            isModelProcessing = true
            
            let faceObservations = detectFaces(in: ciImage)
                        
            guard let largestFaceObservation = getLargestFace(in: faceObservations) else {
                print("Error detecting faces or retrieving largest face")
                return
            }

            let squareFaceBox = squareBoundingBox(from: largestFaceObservation, in: ciImage)
            
            if let highlightedImage = drawRectangle(on: selectedImage, withRect: squareFaceBox) {
                self.displayImage = highlightedImage
            }
            
            let inverseTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -ciImage.extent.height)
            let normalizedCIImage = ciImage.transformed(by: inverseTransform)
            let squareFaceImage = normalizedCIImage.cropped(to: squareFaceBox)

            if let resizedPixelBuffer = resize(image: squareFaceImage, toSize: CGSize(width: 150, height: 150)) {
              
                if let liveModel = modelUpdater.liveModel {
                    let (_, cnnScore) = ModelInference.predictUsingCoreML(using: liveModel, pixelBuffer: resizedPixelBuffer)
                    
                    let finalClassPrediction = cnnScore < 0.5 ? 0 : 1
                    
                    if finalClassPrediction == 0 {
                        confidence = Float(cnnScore * 100)
                        predictionLabel = "Looks like Rishabh"
                    } else {
                        confidence = Float((1.0 - cnnScore) * 100)
                        predictionLabel = "Doesn't look like Rishabh"
                    }
                    
                    isModelProcessing = false
                } else {
                    predictionLabel = "Error processing the image"
                    confidence = 0
                }
            }
        }
    }

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}


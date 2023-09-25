//
//  ContentView.swift
//  PixeLearner
//
//  Created by Rishabh Solanki on 9/13/23.
//
import SwiftUI
import CoreML
import UIKit

struct ContentView: View {
    @State private var isImagePickerPresented: Bool = false
    @State private var predictionLabel: String = "Please select an image"
    @State private var confidence: Float = 0.0
    @State private var feedbackMessage: String = ""
    @State private var displayImage: UIImage?
    @State private var selectedImage: UIImage?
    
    
    //Speech
    @StateObject private var speechManager = SpeechToTextManager()
   
    
    //BERT
    private var bert = BERT()
    @State private var bertAnswer: String = "Start recording to get an answer..."

    
    //Camera
    @State private var isCameraFeedPresented: Bool = false

    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background for the whole view
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.2), Color.blue.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Image Section
                    imageSection
                        .frame(height: 400)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                        .padding([.horizontal,.top])

                    // Audio Section
                    audioSection
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .padding()
                        .foregroundColor(.primary)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                        .padding(.horizontal)

                    // Bert Answer Section
                    Text(bertAnswer)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .padding()
                        .foregroundColor(.primary)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                        .multilineTextAlignment(.center)
                        .padding([.horizontal])

                    
                    // Button Section
                    HStack(spacing: 20) {
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight) {
                            selectImageButton
                        }
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                        .scaleEffect(isImagePickerPresented ? 1.05 : 1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: isImagePickerPresented)
                                        
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight) {
                            liveCameraButton
                        }
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                        .scaleEffect(isCameraFeedPresented ? 1.05 : 1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: isCameraFeedPresented)
                                        
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight) {
                            recordingButton
                        }
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                        .scaleEffect(speechManager.isRecording ? 1.05 : 1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: speechManager.isRecording)
                    }
                    .padding([.top,.horizontal])
                }
            }
            .navigationBarTitle("PixeLearner", displayMode: .inline)
            
            .padding(.bottom, 0)
        }
    }
    
    
    
    var imageSection: some View {
        Group {
            if isCameraFeedPresented {
                CameraFeedView()
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let uiImage = self.displayImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
            } else {
                defaultImageViewContent()
            }
        }
    }


    func defaultImageViewContent() -> some View {
        Image(systemName: "photo.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray)
            .frame(width: 150, height: 150) // A bit smaller for better space usage
    }

    func fetchAnswer() {
        let question = "Who is my friend?"
        let document = speechManager.recognizedText
        let response = bert.findAnswer(for: question, in: document)

        if response.isEmpty {
            bertAnswer = "Couldn't find a valid answer. Please try again."
        } else {
            bertAnswer = String(response)
        }
    }


    var predictionAndFeedbackDisplay: some View {
        VStack(spacing: 10) {
            Text(predictionLabel)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .font(.headline)
            Text("Confidence: \(String(format: "%.2f", confidence * 100))%")
                .font(.subheadline)
                .opacity(confidence > 0 ? 1 : 0)
            Text(feedbackMessage)
                .foregroundColor(.green)
                .opacity(feedbackMessage.isEmpty ? 0 : 1)
        }
        .padding(.horizontal)
    }

    var selectImageButton: some View {
        Button(action: {
            isImagePickerPresented = true
        }) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .padding(10)
                .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                .foregroundColor(.white)
                .cornerRadius(25)
        }
    }

    var liveCameraButton: some View {
        Button(action: {
            isCameraFeedPresented = true
        }) {
            Image(systemName: "camera.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .padding(10)
                .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                .foregroundColor(.white)
                .cornerRadius(25)
        }
    }

    var recordingButton: some View {
        Button(action: {
            if speechManager.isRecording {
                speechManager.stopRecording()
                fetchAnswer()
            } else {
                speechManager.startRecording()
            }
        }) {
            Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .padding(10)
                .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                .foregroundColor(.white)
                .cornerRadius(25)
        }
    }

    var audioSection: some View {
        VStack(spacing: 10) {
            if speechManager.isRecording {
                Text("Recording...")
                    .font(.headline)
                    .padding(.bottom, 5)
            }
           
            ScrollView {
                Text(speechManager.recognizedText)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 5)
            }
        }
    }


    func predictImage(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    
            let faceObservations = detectFaces(in: ciImage)
            
            guard let largestFaceObservation = getLargestFace(in: faceObservations) else {
                print("Error detecting faces or retrieving largest face")
                return
            }
            
            let squareFaceBox = squareBoundingBox(from: largestFaceObservation, in: ciImage)
            
            //if let highlightedImage = drawRectangle(on: selectedImage, withRect: squareFaceBox) {
                //self.displayImage = highlightedImage
            //}
            
            let inverseTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -ciImage.extent.height)
            let normalizedCIImage = ciImage.transformed(by: inverseTransform)
            let squareFaceImage = normalizedCIImage.cropped(to: squareFaceBox)
            
            if let resizedPixelBuffer = resize(image: squareFaceImage, toSize: CGSize(width: 224, height: 224)) {
                
                let (label, cnnScore) = ModelInference.predictUsingCoreML(using: cnn_base(), pixelBuffer: resizedPixelBuffer)
                
                // If the label is "Looks like Rishabh", then we take the cnnScore as the confidence.
                // Otherwise, we take (1 - cnnScore) as the confidence.
                self.confidence = (label == "Looks like Rishabh") ? cnnScore : (1 - cnnScore)
                
                predictionLabel = label

            }
            else {
                predictionLabel = "Error processing the image"
                confidence = 0
            }
        }
        
    }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

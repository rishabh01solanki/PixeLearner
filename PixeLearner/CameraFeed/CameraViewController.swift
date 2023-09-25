import AVFoundation
import SwiftUI

struct CameraFeedView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // No changes here
    }
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession!
    var faceRectangleLayer: CAShapeLayer!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var model: cnn_base? // Add this line

    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        model = cnn_base() // Instantiate the model here
        
        if let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(input)
            } catch {
                print("Error setting up capture device input: \(error)")
                return
            }
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        faceRectangleLayer = CAShapeLayer()
        faceRectangleLayer.strokeColor = UIColor.red.cgColor
        faceRectangleLayer.lineWidth = 1.0
        faceRectangleLayer.fillColor = UIColor.clear.cgColor
        view.layer.addSublayer(faceRectangleLayer)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        ciImage = ciImage.oriented(.right)
        
        let faceObservations = detectFaces(in: ciImage)
        
        DispatchQueue.main.async {
            if let largestFaceObservation = getLargestFace(in: faceObservations) {
                let squareFaceBox = squareBoundingBox(from: largestFaceObservation, in: ciImage)
                let squareFaceImage = ciImage.cropped(to: squareFaceBox)

                if let resizedPixelBuffer = resize(image: squareFaceImage, toSize: CGSize(width: 224, height: 224)),
                   let model = self.model { // Use the model instance created earlier
                    let (label, cnnScore) = ModelInference.predictUsingCoreML(using: model, pixelBuffer: resizedPixelBuffer)
                    
                    // Convert the bounding box from CIImage coordinates to view coordinates
                    let faceRectInView = self.convertRectFromImageToView(squareFaceBox, imageSize: ciImage.extent.size, viewSize: self.view.bounds.size)
                    let facePath = UIBezierPath(rect: faceRectInView)
                    self.faceRectangleLayer.path = facePath.cgPath
                    
                    // Display the prediction label on top of the bounding box
                    self.displayPredictionLabel(label: label, confidence: cnnScore, boundingBox: faceRectInView)
                } else {
                    // Convert the bounding box from CIImage coordinates to view coordinates
                    let faceRectInView = self.convertRectFromImageToView(squareFaceBox, imageSize: ciImage.extent.size, viewSize: self.view.bounds.size)
                    let facePath = UIBezierPath(rect: faceRectInView)
                    self.faceRectangleLayer.path = facePath.cgPath
                }
            } else {
                self.faceRectangleLayer.path = nil // If no face is detected, clear the rectangle path
            }
        }
        
        if faceObservations.isEmpty {
            DispatchQueue.main.async {
                self.view.viewWithTag(1001)?.removeFromSuperview()
            }
        }
    }



    func convertRectFromImageToView(_ rect: CGRect, imageSize: CGSize, viewSize: CGSize) -> CGRect {
        let viewWidth = viewSize.width
        let viewHeight = viewSize.height

        let imageWidth = imageSize.width
        let imageHeight = imageSize.height

        let margin = CGFloat(20.0)

        let scaleX = viewWidth / imageWidth
        let scaleY = viewHeight / imageHeight

        // Adjust the bounding box size with the margin
        let adjustedWidth = rect.width + 2 * margin
        let adjustedHeight = rect.height + 2 * margin
        
        // Calculate the new origin to keep the face centered
        let adjustedOriginX = rect.origin.x - margin
        let adjustedOriginY = rect.origin.y - margin

        // Convert the Y-coordinate to the UIKit's top-left origin
        let newY = (viewHeight - adjustedHeight * scaleY) - adjustedOriginY * scaleY

        return CGRect(
            x: adjustedOriginX * scaleX,
            y: newY,
            width: adjustedWidth * scaleX,
            height: adjustedHeight * scaleY
        )
    }







    func displayPredictionLabel(label: String, confidence: Float, boundingBox: CGRect) {
        // Remove existing prediction label from the view if any
        view.viewWithTag(1001)?.removeFromSuperview()

        // Format the label based on prediction
        let displayLabel = label == "Looks like Rishabh" ? "Rishabh" : "Not Rishabh"
        let labelString = "\(displayLabel) (\(String(format: "%.2f", confidence * 100))%)"
        
        // Calculate the size required for the label string
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)] // Assuming default system font of size 17
        let labelSize = labelString.size(withAttributes: attributes)
        
        // Calculate position to display the label on top of the bounding box
        let padding: CGFloat = 10.0
        let labelHeight: CGFloat = 40.0
        let labelY = max(boundingBox.origin.y - labelHeight - padding, padding) // Prevent label from going off-screen
        
        // Adjust x-position so that the label remains centered above the bounding box
        let labelX = max(boundingBox.midX - labelSize.width / 2.0, padding) // Ensure the label does not go off the left edge
        let maxWidth = view.bounds.width - padding // Max allowable width for label
        let adjustedWidth = min(labelSize.width, maxWidth - labelX)
        
        let predictionLabelFrame = CGRect(x: labelX, y: labelY, width: adjustedWidth, height: labelHeight)
        
        let predictionLabel = UILabel(frame: predictionLabelFrame)
        predictionLabel.text = labelString
        predictionLabel.textColor = UIColor.white
        predictionLabel.textAlignment = .center
        predictionLabel.adjustsFontSizeToFitWidth = true
        predictionLabel.minimumScaleFactor = 0.5
        predictionLabel.backgroundColor = UIColor.red.withAlphaComponent(0.7)
        predictionLabel.tag = 1001  // Assigning a tag to find it later and remove
        
        view.addSubview(predictionLabel)
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }
}


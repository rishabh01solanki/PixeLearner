//
//  crop_resize.swift
//  PixeLearner
//
//  Created by Rishabh Solanki on 9/13/23.
//


import Foundation
import UIKit
import CoreImage
import Vision


func drawRectangle(on image: UIImage, withRect rect: CGRect) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
    let context = UIGraphicsGetCurrentContext()

    // Draw the original image first
    image.draw(at: CGPoint.zero)

    // Set up the rectangle properties
    context?.setStrokeColor(UIColor.red.cgColor)
    context?.setLineWidth(5.0)

    // Convert CGRect from CIImage coordinate to UIImage coordinate
    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -image.size.height)
    let uiImageRect = rect.applying(transform)

    // Draw the rectangle
    context?.stroke(uiImageRect)
    
    let resultImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resultImage
}


func detectFaces(in ciImage: CIImage) -> [VNFaceObservation] {
    var faceObservations: [VNFaceObservation] = []

    // Create a request to detect faces
    let faceDetectionRequest = VNDetectFaceRectanglesRequest { (request, error) in
        guard error == nil else {
            print("Face detection error: \(String(describing: error)).")
            return
        }
        
        faceObservations = request.results as? [VNFaceObservation] ?? []
    }

    // Execute the request with a handler
    let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    do {
        try imageRequestHandler.perform([faceDetectionRequest])
    } catch {
        print("Failed to perform face detection: \(error.localizedDescription).")
    }
    
    return faceObservations
}

func getLargestFace(in faceObservations: [VNFaceObservation]) -> VNFaceObservation? {
    print("Number of faces detected: \(faceObservations.count)")
    return faceObservations.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
}


func squareBoundingBox(from observation: VNFaceObservation, in ciImage: CIImage) -> CGRect {
    // Convert normalized bounding box to image coordinates
    let faceRect = CGRect(
        x: observation.boundingBox.origin.x * ciImage.extent.size.width,
        y: observation.boundingBox.origin.y * ciImage.extent.size.height,
        width: observation.boundingBox.width * ciImage.extent.size.width,
        height: observation.boundingBox.height * ciImage.extent.size.height
    )
    
    // Calculate the side of the square bounding box by taking the minimum dimension
    let sideLength = max(faceRect.width, faceRect.height)
    
    return CGRect(
        x: faceRect.midX - (sideLength / 2),
        y: faceRect.midY - (sideLength / 2),
        width: sideLength,
        height: sideLength
    )
}

func resize(image: CIImage, toSize size: CGSize) -> CVPixelBuffer? {
    let context = CIContext(options: nil)
    var pixelBuffer: CVPixelBuffer?

    let attributes: [String: Any] = [
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        kCVPixelBufferMetalCompatibilityKey as String: true,
        kCVPixelBufferOpenGLCompatibilityKey as String: true
    ]

    CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, attributes as CFDictionary, &pixelBuffer)
    guard let buffer = pixelBuffer else {
        return nil
    }

    // Translate the image to ensure its contents begin at (0,0)
    let translatedImage = image.transformed(by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y))

    // Calculate the scale factor
    let scale = min(size.width / translatedImage.extent.width, size.height / translatedImage.extent.height)
    let scaledImage = translatedImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    


    // Render the scaled image to pixel buffer
    context.render(scaledImage, to: buffer, bounds: CGRect(origin: .zero, size: size), colorSpace:nil)

    return buffer
}


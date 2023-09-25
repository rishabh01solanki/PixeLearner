//
//  ImageUtils.swift
//  PixeLearner
//
//  Created by Rishabh Solanki on 9/13/23.
//


import Foundation
import UIKit
import AVFoundation




func buffer(from image: UIImage) -> CVPixelBuffer? {
    let imageWidth = Int(image.size.width)
    let imageHeight = Int(image.size.height)
    
    var pixelBuffer: CVPixelBuffer? = nil
    let pixelBufferAttributes: [CFString: Any] = [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true
    ]
    
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     imageWidth,
                                     imageHeight,
                                     kCVPixelFormatType_32BGRA,
                                     pixelBufferAttributes as CFDictionary,
                                     &pixelBuffer)
    
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
        return nil
    }
    
    CVPixelBufferLockBaseAddress(buffer, [])
    
    let pixelData = CVPixelBufferGetBaseAddress(buffer)
    
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: pixelData,
                                  width: imageWidth,
                                  height: imageHeight,
                                  bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                  space: rgbColorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return nil
    }
    
    UIGraphicsPushContext(context)
    image.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
    UIGraphicsPopContext()
    
    CVPixelBufferUnlockBaseAddress(buffer, [])
    
    return buffer
}


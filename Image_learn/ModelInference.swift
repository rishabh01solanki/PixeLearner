//
//  ModelInference.swift
//  Image_learn
//
//  Created by Rishabh Solanki on 9/6/23.
//
import Foundation
import CoreML
import CoreML

struct ModelInference {
    static func predictUsingCoreML(using model: cnn, pixelBuffer: CVPixelBuffer) -> (String, Float) {
        
        do {
            let input = cnnInput(conv2d_input: pixelBuffer)
            let output = try model.prediction(input: input)
            print("Prediction was successful.") // Debugging
            
            // Extracting the probability from the MLMultiArray output
            if let identity = output.Identity as? MLMultiArray {
                let meProbability = identity[0].floatValue
                print("identity :", identity)
                
                // Determine the label based on the threshold
                let label = meProbability > 0.5 ? "Looks like Rishabh" : "Doesn't look like Rishabh"

                // Return the label and the corresponding probability
                return (label, meProbability)
            } else {
                return ("Could not extract MLMultiArray from output", 0.0)
            }
        }
        catch {
            print("Error while doing predictions: \(error)")
            return ("Prediction failed", 0.0)
        }
    }
}

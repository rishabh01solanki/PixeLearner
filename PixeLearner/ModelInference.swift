//
//  ModelInference.swift
//  PixeLearner
//
//  Created by Rishabh Solanki on 9/13/23.
//

import CoreML

struct ModelInference {
    static func predictUsingCoreML(using model: cnn_base, pixelBuffer: CVPixelBuffer) -> (String, Float) {
        
        do {
            let input = cnn_baseInput(input_1: pixelBuffer)
            let output = try model.prediction(input: input)
            print("Prediction was successful.") // Debugging
            
            // Extract the predicted label from the model's output
            let predictedLabel = output.classLabel

            // Check if there's a corresponding probability for the predicted label
            if let predictedProbability = output.Identity[predictedLabel] {
                print("Predicted label:", predictedLabel)
                print("Probability for predicted label:", predictedProbability)

                // Convert the label "me" to "Looks like Rishabh"
                let finalLabel = predictedLabel == "me" ? "Looks like Rishabh" : "Doesn't look like Rishabh"
                
                return (finalLabel, Float(predictedProbability))
                
            } else {
                return ("Error extracting probability for predicted label", 0.0)
            }

        } catch {
            print("Error while doing predictions: \(error)")
            return ("Prediction failed", 0.0)
        }
    }
}

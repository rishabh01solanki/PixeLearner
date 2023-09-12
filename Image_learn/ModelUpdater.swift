import CoreML

class ModelUpdater {
    
    
    
    // Properties
    private var updatedCNN: cnn?
    
    private var defaultCNN: cnn? {
        do {
            return try cnn(configuration: .init())
        } catch {
            print("Error loading default cnn model: \(error.localizedDescription)")
            return nil
        }
    }
    
    var liveModel: cnn? {
        if updatedCNN == nil {
            loadUpdatedModel()
        }
        return updatedCNN ?? defaultCNN
    }
    
    private let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var defaultModelURL: URL { cnn.urlOfModelInThisBundle }
    var updatedModelURL: URL {
        return documentDirectory.appendingPathComponent("cnn.mlmodelc")
    }

    func predictUsingCoreML(pixelBuffer: CVPixelBuffer) -> (String, Float)? {
        if liveModel == nil {
            loadUpdatedModel()
        }
        
        guard let liveModel = liveModel else {
            print("No model available for prediction.")
            return nil
        }
        
        return ModelInference.predictUsingCoreML(using: liveModel, pixelBuffer: pixelBuffer)
    }
    
    func updateWith(trainingData: MLArrayBatchProvider, completionHandler: @escaping () -> Void) {
        let fileManager = FileManager.default
        let modelURL = fileManager.fileExists(atPath: updatedModelURL.path) ? updatedModelURL : defaultModelURL
        print("file location: ", modelURL)
        
        func updateModelCompletionHandler(updateContext: MLUpdateContext) {
            saveUpdatedModel(updateContext)
            DispatchQueue.main.async { completionHandler() }
        }
        
        do {
            let updateTask = try MLUpdateTask(forModelAt: modelURL,
                                              trainingData: trainingData,
                                              configuration: nil,
                                              completionHandler: updateModelCompletionHandler)
            updateTask.resume()
        } catch {
            print("Error creating MLUpdateTask: \(error)")
        }
    }
    
    private func saveUpdatedModel(_ updateContext: MLUpdateContext) {
        
        let updatedModel = updateContext.model
        let fileManager = FileManager.default
        let tempUpdatedModelURL = documentDirectory.appendingPathComponent("temp_cnn.mlmodelc")
        
        do {
            // Check and remove the temporary model file if it exists.
            if fileManager.fileExists(atPath: tempUpdatedModelURL.path) {
                try fileManager.removeItem(at: tempUpdatedModelURL)
            }
            
            // Create a directory for the updated model.
            try fileManager.createDirectory(at: tempUpdatedModelURL.deletingLastPathComponent(),
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            
            // Save the updated model to the temporary location.
            try updatedModel.write(to: tempUpdatedModelURL)
            
            // Replace any previously updated model with this one.
            if fileManager.fileExists(atPath: updatedModelURL.path) {
                try fileManager.removeItem(at: updatedModelURL)
            }
            try fileManager.moveItem(at: tempUpdatedModelURL, to: updatedModelURL)
            
            print("Updated model saved to:\n\t\(updatedModelURL.path)")
            
            // Load the updated model.
            loadUpdatedModel()
            
        } catch {
            print("Could not save updated model to the file system: \(error.localizedDescription)")
        }
    }



    private func loadUpdatedModel() {
        if FileManager.default.fileExists(atPath: updatedModelURL.path) {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all
            configuration.allowLowPrecisionAccumulationOnGPU = true
            
            
            
            do {
                let model = try cnn(contentsOf: updatedModelURL, configuration: configuration)
                updatedCNN = model
                print("Updated model successfully loaded.")
            } catch {
                print("Error loading updated model: \(error)")
                updatedCNN = defaultCNN
            }
        } else {
            print("Updated model not found. Falling back to default.")
            updatedCNN = defaultCNN
        }
    }
}


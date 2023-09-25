//
//  ImagePickerCoordinator.swift
//  PixeLearner
//
//  Created by Rishabh Solanki on 9/13/23.
//

import Foundation
import UIKit

final class ImagePickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var parent: ImagePicker
    
    init(_ parent: ImagePicker) {
        self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let uiImage = info[.originalImage] as? UIImage {
            parent.image = uiImage
        }
        parent.presentationMode.wrappedValue.dismiss()
    }
}

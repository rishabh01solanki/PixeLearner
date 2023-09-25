# PixeLearner

This iOS application uses on-device machine learning to make predictions based on images. The primary advantage is privacy - all predictions and updates are done locally on the device. It's initially trained on a set of images, but the model can learn and adapt to user-specific data using updatable layers.

<p align="center">
  <img src="PixeLearner.gif" alt="Recognizing the person" width="300"/>
</p>



## Key Features

- **On-Device Machine Learning**: All the machine learning operations are done on the device, ensuring user data privacy.
- **Built on MobileNetV2**: The architecture uses the power of MobileNetV2 and adds two updatable layers on top for personalization.
- **Updatable Model**: The model can adapt and update based on new data.
- **Easy Integration**: The project is structured as an Xcode project for easy integration and deployment.

## Getting Started

### Prerequisites

- Xcode (latest version)
- iOS device for deployment
- CoreMLtools (ensure it's installed)

### Installation and Running

1. Clone this repository:
```
git clone https://github.com/rishabh01solanki/PixeLearner.git
```
2. Open the Xcode project in Xcode.
3. Connect your iOS device.
4. Build and run the project to deploy the application on your device.

### Usage
- Capture or upload an image using the app interface.
- The app will make a prediction based on the current model state.
- Provide feedback to the model if the prediction is correct or not.
- The app will learn from the feedback and adjust the model accordingly for better future predictions.

### Upcoming
Stay tuned for the newer version, which will soon be available on the App Store!

### Contributing
Feel free to open issues, suggest improvements, and make pull requests. Your contributions are welcome!

### License
This project is open source, under MIT license.

## Acknowledgments
MobileNetV2 creators for the base model architecture.
CoreML tools for enabling on-device machine learning.

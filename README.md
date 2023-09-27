## PixeLearner: A Personalized ML-Powered App

**PixeLearner** is a cutting-edge application that uses a combination of state-of-the-art Machine Learning algorithms to recognize and label individuals in real-time. Its strength lies in its ability to not only recognize individuals from visual data but also associate labels using natural language processing.

### Overview
**Objective:** To label people you know easily in a natural way, almost like making introductions in person.

**Use Cases:** 
- Recognizing friends or family from live camera feed.
- Making quick introductions by associating a name with a face.
- Training the model in real-time with new introductions.

<p align="center">
  <img src="PixeLearner.gif" alt="Recognizing the person" width="300"/>
</p>

**Advantage:** 
- On-device processing ensures user data privacy.
- Offers potential extensions to a variety of applications.
- Provides a great learning experience for developers diving into ML and NLP integration.

### How Does it Work?

1. **Camera Feed**: Using the AV Foundation, the app captures live video feed and processes each frame. Special care is taken to ensure resources are utilized efficiently and no memory leaks occur.

2. **Model Inference**: Each frame captured is processed by a custom CNN (MobileNetV2). This model processes the image and provides feature embeddings for the face detected.

3. **Speech Recognition**: The user can vocalize labels (like names) using a speech-to-text module. This takes the user's spoken words and converts them to a textual format. 

4. **BERT NLP**: The textual data is then processed by BERT, a state-of-the-art NLP algorithm, to ensure it is tokenized and properly formatted. If a token is not in BERT’s vocabulary, it uses Apple's NLTagger from the NLToolkit to further split and label the string.

5. **Connecting the Dots**: Once we have feature embeddings from the CNN and labels from BERT, we can associate the two. Thus, when a recognized face appears in the camera feed, the app can label them in real-time.

6. **Model Update**: Over time, as more labels are introduced and recognized, the model can be updated to improve its accuracy.

### Technical Details:

- **Camera Feed**:
    - Uses AV Foundation to capture live video.
    - The frame is processed and prepared (like squaring, resizing, etc.) before inference.
    - The face's coordinates in the frame are sent to a face preview layer for better visualization.
  
- **BERT-NLP**:
    - Tokenizes strings into words and word pieces.
    - Uses Apple's NLTagger for splitting strings if necessary.
    - Can further split strings until a match is found in the vocabulary or label it as unknown.
  
- **Speech to Text**:
    - An observable class that starts and stops recording based on user interaction.
    - Outputs translated audio to text.
  
- **Inference**:
    - The model takes pixel buffer as input and returns a label and confidence score.
    - Errors are caught and handled gracefully.
  
- **Update**:
    - A model update class takes in training data and a completion handler.
    - After updating, the updated model is saved and the context is refreshed to refer to the updated model.


### Future Scope:
With the foundation in place, future versions can potentially integrate more complex ML models, offer cloud-based model updates, and perhaps even extend into AR/VR spaces.


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

### Upcoming
Stay tuned for the newer version, which will soon be available on the App Store!

### Contributing
Feel free to open issues, suggest improvements, and make pull requests. Your contributions are welcome!

### License
This project is open source, under MIT license.

## Acknowledgments
MobileNetV2 creators for the base model architecture.
CoreML tools for enabling on-device machine learning.

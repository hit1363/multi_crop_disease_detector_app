# multi_crop_disease_detector

Flutter mobile application for detecting plant diseases using an EfficientNetB0 TensorFlow Lite model with on-device inference.

##  Features

### Core Functionality
- **Real-time Disease Detection**: Use camera to capture leaf images and get instant diagnosis
- **Multi-Crop Support**: Detects 67 classes across 16 crops (Tomato, Potato, Corn, Apple, Grape, Banana, Mango, Rice, Sugarcane, Wheat, etc.)
- **Offline Inference**: All processing happens on-device using TensorFlow Lite
- **High Accuracy**: 87.1% test accuracy with an EfficientNetB0 model
- **Fast Performance**: Fully on-device float32 inference, no network round trip

### User Features
- **Scan History**: SQLite database stores all previous scans with timestamps
- **Treatment Recommendations**: Detailed treatment guides (cultural, chemical, biological)
- **Disease Information**: Comprehensive disease descriptions and symptoms
- **Statistics Dashboard**: Track scans by crop, disease frequency, and success rates
- **Image Gallery**: Pick images from gallery for analysis
- **Search & Filter**: Filter history by crop type and search by disease name

### Technical Features
- **Material Design 3**: Modern UI with custom theme
- **Camera Integration**: Live preview with flash control and camera switching
- **Image Preprocessing**: Validation, quality checks, and optimization
- **Result Confidence**: Top-3 predictions with confidence scores
- **Responsive Design**: Optimized for phones and tablets

##  Model Details

### Supported Crops & Diseases
- The app currently targets the training dataset labels in `assets/labels/labels.txt`
- This project configuration uses **67 classes** (16 crops plus an explicit `Invalid` class)
- If you retrain with a different class set, regenerate `assets/labels/labels.txt` and replace the model in `assets/models/`, then update `MLService.modelAssetPath`

### Model Performance
- **Architecture**: EfficientNetB0, ImageNet pre-trained, fine-tuned
- **Input**: 224x224 float32 RGB, raw 0-255 (the graph bakes in rescaling and ImageNet normalization)
- **Output**: 67-class softmax
- **Accuracy**: 87.1% on the held-out test split
- **Model Size**: ~16.7 MB (float32, no post-training quantization applied)

Precision/recall/F1 and the per-backbone comparison (MobileNetV1/V2/V3, NASNetMobile,
EfficientNetB0, EfficientNetV2-B0, ShuffleNetV2-0.5) live in the training repository.

### Training Details
- **Training repository**: [An-Efficient-Multi-Crop-Leaf-Disease-Detection-System](https://github.com/hit1363/An-Efficient-Multi-Crop-Leaf-Disease-Detection-System) - dataset preparation, training, comparison and quantization scripts
- **Base Model**: ImageNet pre-trained EfficientNetB0
- **Dataset**: 67 canonical classes over 16 crops, prepared with a deterministic 70/15/15 split
- **Input pipeline**: 224x224 Lanczos center-crop
- **Recipe**: head frozen for 20 epochs, then the top layers unfrozen for 30 fine-tune epochs
- **Optimizer**: Adam (3e-4) with gradient clipping
- **Loss**: categorical cross-entropy with label smoothing

## 📄 License

MIT License - See LICENSE file for details

## 👥 Contributors

Developed as part of a Bachelor's thesis:
**"An Efficient Multi-Crop Leaf Disease Detection System Using Deep Learning"**

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request


## 🔮 Future Enhancements

- [ ] Cloud sync for scan history
- [ ] Crop health tracking over time
- [ ] Community features (share results)
- [ ] Weather integration
- [ ] Fertilizer recommendations
- [ ] Pest detection (beyond diseases)
- [ ] AR visualization of treatments
- [ ] Voice-guided scanning
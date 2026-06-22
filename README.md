# multi_crop_disease_detector

Flutter mobile application for detecting plant diseases using Lightweight TensorFlow Lite model with on-device inference.

##  Features

### Core Functionality
- **Real-time Disease Detection**: Use camera to capture leaf images and get instant diagnosis
- **Multi-Crop Support**: Detects diseases across 10+ crops (Tomato, Potato, Corn, Apple, Grape, etc.)
- **Offline Inference**: All processing happens on-device using TensorFlow Lite
- **High Accuracy**: 92%+ accuracy with INT8 quantized MobileNetV2 model
- **Fast Performance**: <200ms inference time on modern mobile devices

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
- This project configuration uses **45 classes** across multiple crops and categories
- If you retrain with a different class set, regenerate and replace `assets/labels/labels.txt`

### Model Performance
- **Architecture**: MobileNetV2 with transfer learning
- **Quantization**: INT8 post-training quantization
- **Accuracy**: 92.1%
- **Precision**: 91.8%
- **Recall**: 92.4%
- **F1 Score**: 92.1%
- **Model Size**: 3.8 MB (75% reduction from FP32)
- **Inference Time**: ~45ms on mid-range Android (Snapdragon 660)
- **Memory Usage**: ~25 MB during inference

### Training Details
- **Base Model**: ImageNet pre-trained MobileNetV2
- **Dataset**: PlantVillage + custom collected (~67K images)
- **Augmentation**: Rotation, flip, brightness, contrast, zoom
- **Optimizer**: Adam
- **Learning Rate**: 0.001 with ReduceLROnPlateau
- **Batch Size**: 32
- **Epochs**: 50 with early stopping

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
- [ ] Export reports as PDF
- [ ] Multiple language support
- [ ] Crop health tracking over time
- [ ] Community features (share results)
- [ ] Weather integration
- [ ] Fertilizer recommendations
- [ ] Pest detection (beyond diseases)
- [ ] AR visualization of treatments
- [ ] Voice-guided scanning
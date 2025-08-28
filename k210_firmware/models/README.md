# K210 AI Models Directory

This directory contains the AI models for the T-Bao K210 AI engine.

## Required Models

### Face Detection
- **File**: `face_detect.kmodel`
- **Description**: YOLOv2-based face detection model optimized for K210
- **Input**: 320x240 RGB565 image
- **Output**: Face bounding boxes with confidence scores

### Wake Word Detection (Optional)
- **File**: `wake_word.kmodel`
- **Description**: Lightweight wake word detection for voice activation
- **Input**: Audio features (MFCC)
- **Output**: Wake word probability

## Model Sources

### Pre-trained Models
You can download pre-trained models from:

1. **Sipeed Model Zoo**: https://dl.sipeed.com/MAIX/MaixPy/model
2. **Official K210 Models**: https://github.com/sipeed/MaixPy_scripts/tree/master/machine_vision

### Recommended Models for T-Bao

1. **Face Detection**:
   ```bash
   # Download face detection model
   wget https://dl.sipeed.com/MAIX/MaixPy/model/face_model_at_0x300000.kfpkg
   ```

2. **Object Detection** (Optional):
   ```bash
   # Download 20-class object detection
   wget https://dl.sipeed.com/MAIX/MaixPy/model/20class_yolo_model.kfpkg
   ```

## Model Installation

1. Copy `.kmodel` files to the SD card root directory or this models folder
2. Update the model paths in `main.py`:
   ```python
   face_detection_model = kpu.load("/sd/face_detect.kmodel")
   # or
   face_detection_model = kpu.load("models/face_detect.kmodel")
   ```

## Custom Model Training

For training custom models:

1. **Use nncase**: Convert TensorFlow/ONNX models to K210 format
2. **MaixHub**: Online training platform for K210 models
3. **K210 Training**: Local training with K210 toolchain

## Model Performance

| Model | Input Size | FPS | Accuracy | Memory Usage |
|-------|------------|-----|----------|--------------|
| Face Detection | 320x240 | 15-20 | 95%+ | ~2MB |
| Wake Word | Audio | 30+ | 90%+ | ~500KB |
| Object Detection | 224x224 | 10-15 | 85%+ | ~3MB |

## Notes

- K210 has limited memory (~8MB), choose models carefully
- Models should be optimized for K210 architecture
- Use quantized models for better performance
- Test models thoroughly before deployment

# Meta-Classifier Module

## Purpose
This module combines detections from four YOLO hazard-detection models.

The workflow is:

1. Four YOLO models detect campus hazards.
2. Local class labels are mapped to global labels.
3. Overlapping detections are grouped using IoU.
4. A neural-network meta-classifier predicts the final hazard class.
5. The system outputs the final label and confidence score.

## Model Performance

- Dataset size: 105 samples
- Training samples: 84
- Test samples: 21
- Accuracy: 0.952
- Macro Precision: 0.974
- Macro Recall: 0.974
- Macro F1-score: 0.969

## Files

- `trained_meta_classifier.pkl`  
  Trained MLP meta-classifier.

- `label_encoder.joblib`  
  Encoder used to convert class names and class IDs.

- `feature_columns.joblib`  
  Feature order used during model training and inference.

- `label_mapping.py`  
  Global class list and label harmonisation mapping.

- `inference_pipeline.py`  
  IoU grouping and meta-classifier inference logic.

- `results/confusion_matrix.png`  
  Meta-classifier confusion matrix.

- `results/classification_report.txt`  
  Precision, recall, F1-score and support for each class.

- `results/metrics.json`  
  Summary of evaluation metrics.

## Limitation

This meta-classifier was trained using a prototype ensemble-generated dataset.
The current results are suitable for prototype demonstration, but a larger
human-verified dataset is required for stronger real-world evaluation.

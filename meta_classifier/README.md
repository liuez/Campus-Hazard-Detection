# Meta-Classifier

This folder contains the feature extraction and neural-network meta-classifier training workflow.

## Goal

The meta-classifier combines outputs from four individual YOLO models and predicts the final global hazard class.

## Suggested Features

- YOLO confidence scores.
- Predicted class IDs and normalised global labels.
- Model ID.
- Bounding box `x`, `y`, `width`, `height`, and area.
- IoU between overlapping detections.
- Number of models agreeing on the same or related label.
- Zone or context, such as road, corridor, laboratory, or student college.
- Model reliability score, if available.

## Suggested Neural Network

```text
Input features
-> Dense layer with ReLU
-> Dense layer with ReLU
-> Softmax over global hazard classes
```

## Required Evaluation

- Accuracy
- Precision
- Recall
- F1-score
- Confusion matrix
- Comparison with at least one individual YOLO model
- At least five examples of conflict resolution


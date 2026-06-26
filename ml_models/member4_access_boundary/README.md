# Member 4 YOLO Model

## Focus Area

Access and boundary hazards.

## Files To Add

- `weights/best.pt`
- `weights/last.pt`
- `data.yaml`
- `args.yaml`
- `results/results.csv`
- `results/results.png`
- `results/confusion_matrix.png`
- `results/confusion_matrix_normalized.png`
- `results/BoxF1_curve.png`
- `results/BoxPR_curve.png`
- `results/BoxP_curve.png`
- `results/BoxR_curve.png`
- Validation examples in `results/val_batch*_labels.jpg` and `results/val_batch*_pred.jpg`

## Model Card

| Item | Value |
|---|---|
| YOLO version | YOLOv8n |
| Classes | `missing_barricade`, `damaged_warning_sign`, `broken_handrail`, `blocked_walkway`, `damaged_sidewalk` |
| Dataset size | Labels distribution shown in `results/labels.jpg`; private dataset is not included in this public repository |
| Train/validation/test split | Train and validation split reconstructed in `data.yaml`; original training data is private |
| Epochs | 50 |
| Batch size | 16 |
| Image size | 640 |
| Learning rate | `lr0=0.01`, `lrf=0.01` |
| Optimizer | AdamW |
| Device | GPU (`device=0` in training args) |
| mAP@0.5 | 0.43885 |
| mAP@0.5:0.95 | 0.27012 |
| Precision | 0.70568 |
| Recall | 0.37992 |

## Error Analysis

- False positives: To be filled after reviewing validation predictions.
- False negatives: To be filled after reviewing validation predictions.
- Common class confusion: Access and boundary hazards can overlap visually with walkway obstructions, especially blocked walkway, missing barricade, and damaged sidewalk.
- Improvement attempts: Final version trained for 50 epochs using YOLOv8n and AdamW, with validation plots saved in `results/`.

## Notes

The original `data.yaml` was produced in a Colab path (`/content/member4_access_safety_hazards/dataset_balanced/data.yaml`) and was not included in the provided folder. This repository includes a reconstructed `data.yaml` based on the class names visible in `results/labels.jpg`.

The annotated dataset is intentionally not included in this GitHub repository. It should be shared with the course instructor through Google Drive according to the assignment requirement.

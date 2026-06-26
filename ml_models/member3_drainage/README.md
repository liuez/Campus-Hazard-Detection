# Member 3 YOLO Model

## Focus Area

Drainage and ground hole hazards.

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
| YOLO version | YOLOv8n checkpoint |
| Classes | `open_drain`, `uncovered_manhole`, `pothole`, `uneven_pavement`, `cracked_pavement` |
| Dataset size | Labels distribution shown in `results/labels.jpg`; private dataset is not included in this public repository |
| Train/validation/test split | Train and validation split reconstructed in `data.yaml`; original training data is private |
| Epochs | 1 checkpoint-generation epoch in provided `args.yaml`; full training history was not included in the provided folder |
| Batch size | 16 |
| Image size | 640 |
| Learning rate | `lr0=0.01`, `lrf=0.01` |
| Optimizer | auto |
| Device | GPU (`device=0` in training args) |
| mAP@0.5 | 0.68859 |
| mAP@0.5:0.95 | 0.40315 |
| Precision | 0.75127 |
| Recall | 0.62433 |

## Error Analysis

- False positives: To be filled after reviewing validation predictions.
- False negatives: To be filled after reviewing validation predictions.
- Common class confusion: Ground-hole and pavement classes can overlap visually, especially pothole, open drain, uncovered manhole, uneven pavement, and cracked pavement.
- Improvement attempts: Provided folder contains checkpoint-generation training metadata and validation plots in `results/`.

## Notes

The original `data.yaml` was produced in a Colab path (`/content/final_dataset/data.yaml`) and was not included in the provided folder. This repository includes a reconstructed `data.yaml` based on the class names visible in `results/labels.jpg`.

The provided `args.yaml` and `results.csv` show a 1 epoch checkpoint-generation run from `/content/best.pt`. The model weights and evaluation artifacts are included, but the full original multi-epoch training log was not included in the provided folder.

The annotated dataset is intentionally not included in this GitHub repository. It should be shared with the course instructor through Google Drive according to the assignment requirement.

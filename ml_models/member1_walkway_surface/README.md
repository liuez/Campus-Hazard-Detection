# Member 1 YOLO Model

## Focus Area

Walkway and surface hazards.

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
| Classes | `pothole`, `cracked_pavement`, `wet_slippery_floor`, `surface_damage`, `damaged_sidewalk` |
| Dataset size | See private Google Drive dataset and `data.yaml` |
| Train/validation/test split | Train and validation split defined in `data.yaml`; dataset is not included in this public repository |
| Epochs | 20 |
| Batch size | 8 |
| Image size | 640 |
| Learning rate | `lr0=0.01`, `lrf=0.01` |
| Optimizer | auto |
| Device | CPU |
| mAP@0.5 | 0.55663 |
| mAP@0.5:0.95 | 0.33689 |
| Precision | 0.59068 |
| Recall | 0.53091 |

## Error Analysis

- False positives: To be filled after reviewing validation predictions.
- False negatives: To be filled after reviewing validation predictions.
- Common class confusion: Surface-related classes may overlap visually, especially cracked pavement, surface damage, and damaged sidewalk.
- Improvement attempts: Final version trained for 20 epochs using YOLOv8n with augmentation and validation plots saved in `results/`.

## Notes

The annotated dataset is intentionally not included in this GitHub repository. It should be shared with the course instructor through Google Drive according to the assignment requirement.

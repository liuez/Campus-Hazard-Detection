# Member 2 YOLO Model

## Focus Area

Obstruction hazards.

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
| Classes | `obstacle_on_walkway`, `construction_debris`, `fallen_branch`, `traffic_cone`, `wet_slippery_floor` |
| Dataset size | Labels distribution shown in `results/labels.jpg`; private dataset is not included in this public repository |
| Train/validation/test split | Train and validation split reconstructed in `data.yaml`; original training data is private |
| Epochs | 20 |
| Batch size | 16 |
| Image size | 640 |
| Learning rate | `lr0=0.01`, `lrf=0.01` |
| Optimizer | auto |
| Device | GPU (`device=0` in training args) |
| mAP@0.5 | 0.54646 |
| mAP@0.5:0.95 | 0.33888 |
| Precision | 0.58153 |
| Recall | 0.54959 |

## Error Analysis

- False positives: To be filled after reviewing validation predictions.
- False negatives: To be filled after reviewing validation predictions.
- Common class confusion: Obstruction classes may overlap visually, especially obstacle on walkway, construction debris, traffic cone, and fallen branch depending on campus context.
- Improvement attempts: Final version trained for 20 epochs using YOLOv8n with validation plots saved in `results/`.

## Notes

The original `data.yaml` was produced in a Colab path (`/content/member2_work/final_dataset_medium/data.yaml`) and was not included in the provided folder. This repository includes a reconstructed `data.yaml` based on the class names visible in `results/labels.jpg`.

The annotated dataset is intentionally not included in this GitHub repository. It should be shared with the course instructor through Google Drive according to the assignment requirement.

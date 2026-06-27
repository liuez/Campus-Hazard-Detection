# Campus Hazard Detection

CSC4602 Machine Learning project: a mobile campus hazard detection system using four member-trained YOLO object detectors, a neural-network meta-classifier, and LLM-based recommended maintenance actions.

## Project Overview

This repository integrates:

- Four individual YOLO hazard detection models.
- A global label mapping and harmonisation strategy.
- A neural-network meta-classifier that resolves overlapping or conflicting YOLO predictions.
- A mobile app prototype for real-time inference.
- LLM-based recommended maintenance actions.
- Technical report materials, testing evidence, and project documentation.

## Repository Structure

```text
Campus-Hazard-Detection/
|-- mobile_app/
|   |-- lib/
|   |-- android/
|   |-- web/
|   |-- backend/
|   `-- README.md
|-- ml_models/
|   |-- member1_walkway_surface/
|   |-- member2_obstruction/
|   |-- member3_drainage/
|   `-- member4_access_boundary/
|-- meta_classifier/
|   |-- feature_extraction.ipynb
|   |-- meta_classifier_training.ipynb
|   `-- README.md
|-- llm_recommendation/
|   `-- README.md
|-- report/
|   |-- figures/
|   |-- tables/
|   |-- technical_report.pdf
|   `-- README.md
|-- docs/
|   |-- Global_Label_Mapping_Table.xlsx
|   `-- screencast_link.md
`-- README.md
```

## Project Screencast

[Watch the Campus Hazard Detection project demonstration](https://drive.google.com/file/d/1CzNL2_CdHcEAqso6Kb3hkSigkdfNuNHR/view?usp=sharing)

## Member Model Summary

| Member | Model Folder | Focus Area | Five Hazard Classes | Overlap Class |
|---|---|---|---|---|
| Member 1 | `ml_models/member1_walkway_surface/` | Walkway and surface hazards | `pothole`, `cracked_pavement`, `wet_slippery_floor`, `surface_damage`, `damaged_sidewalk` | To be confirmed with other members |
| Member 2 | `ml_models/member2_obstruction/` | Obstruction hazards | `obstacle_on_walkway`, `construction_debris`, `fallen_branch`, `traffic_cone`, `wet_slippery_floor` | `wet_slippery_floor` overlaps with Member 1 |
| Member 3 | `ml_models/member3_drainage/` | Drainage and ground hole hazards | `open_drain`, `uncovered_manhole`, `pothole`, `uneven_pavement`, `cracked_pavement` | `pothole` and `cracked_pavement` overlap with Member 1 |
| Member 4 | `ml_models/member4_access_boundary/` | Access and boundary hazards | `missing_barricade`, `damaged_warning_sign`, `broken_handrail`, `blocked_walkway`, `damaged_sidewalk` | `damaged_sidewalk` overlaps with Member 1; `blocked_walkway` is contextually related to Member 2 obstruction classes |

## Required Outputs

- Individual YOLO model files and training results.
- Global label mapping table.
- Meta-classifier feature extraction and training code.
- Meta-classifier evaluation results.
- Mobile app prototype.
- LLM recommendation module.
- Technical report.
- 8 to 12 minute screencast.
- Daily logbook.

## Dataset Notice

The annotated dataset should not be made public in this GitHub repository. It should be shared with the course instructor through Google Drive according to the assignment requirement.

## Current Integration Checklist

- [x] Add four members' YOLO model files and `data.yaml` files.
- [x] Fill each member's model card.
- [x] Complete the global label mapping table.
- [x] Build feature vectors for the meta-classifier.
- [x] Train and evaluate the meta-classifier.
- [x] Add meta-classifier conflict resolution examples.
- [ ] Run all YOLO models on a shared live/mobile test set.
- [x] Integrate inference into the mobile app.
- [x] Connect LLM recommendation output.
- [ ] Prepare report figures, tables, screenshots, and screencast.

## Meta-Classifier Status

The `meta_classifier/` folder contains the prototype neural-network meta-classifier, feature extraction notebook, training notebook, inference pipeline, label mapping, trained model, and evaluation results.

Key evaluation files:

- `meta_classifier/results/metrics.json`
- `meta_classifier/results/classification_report.txt`
- `meta_classifier/results/confusion_matrix.png`
- `meta_classifier/conflict_resolution_examples.md`

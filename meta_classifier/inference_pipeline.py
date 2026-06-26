import joblib
import pandas as pd
from collections import Counter
from statistics import mean

def calculate_iou(box_a, box_b):
    x1 = max(box_a[0], box_b[0])
    y1 = max(box_a[1], box_b[1])
    x2 = min(box_a[2], box_b[2])
    y2 = min(box_a[3], box_b[3])

    intersection = max(0, x2 - x1) * max(0, y2 - y1)

    area_a = max(0, box_a[2] - box_a[0]) * max(0, box_a[3] - box_a[1])
    area_b = max(0, box_b[2] - box_b[0]) * max(0, box_b[3] - box_b[1])

    union = area_a + area_b - intersection

    return intersection / union if union > 0 else 0.0


def related_hazard(label_a, label_b):
    if label_a == label_b:
        return True

    related_groups = [
        {"pothole", "open_drain", "uncovered_manhole"},
        {"surface_damage", "damaged_sidewalk", "uneven_pavement", "cracked_pavement"},
        {"obstacle_on_walkway", "construction_debris", "fallen_branch", "blocked_walkway"}
    ]

    return any(
        label_a in group and label_b in group
        for group in related_groups
    )


def build_meta_feature_row(group, global_classes):
    confidences = [d["confidence"] for d in group]
    labels = [d["label"] for d in group]
    model_names = sorted(set(d["model"] for d in group))

    best_det = max(group, key=lambda d: d["confidence"])
    x1, y1, x2, y2 = best_det["box"]

    width = max(0, x2 - x1)
    height = max(0, y2 - y1)
    area = width * height

    iou_values = []

    for i in range(len(group)):
        for j in range(i + 1, len(group)):
            iou_values.append(
                calculate_iou(group[i]["box"], group[j]["box"])
            )

    label_counts = Counter(labels)

    row = {
        "best_confidence": max(confidences),
        "mean_confidence": mean(confidences),
        "min_confidence": min(confidences),
        "agreement_count": len(model_names),
        "detection_count": len(group),
        "max_iou": max(iou_values) if iou_values else 0.0,
        "mean_iou": mean(iou_values) if iou_values else 0.0,
        "best_box_x1": x1,
        "best_box_y1": y1,
        "best_box_width": width,
        "best_box_height": height,
        "best_box_area": area,
        "member1_detected": int("member1" in model_names),
        "member2_detected": int("member2" in model_names),
        "member3_detected": int("member3" in model_names),
        "member4_detected": int("member4" in model_names),
    }

    for label in global_classes:
        row[f"{label}_votes"] = label_counts[label]

    return row


class MetaClassifierPipeline:
    def __init__(
        self,
        model_path="trained_meta_classifier.pkl",
        encoder_path="label_encoder.joblib",
        feature_path="feature_columns.joblib"
    ):
        self.model = joblib.load(model_path)
        self.label_encoder = joblib.load(encoder_path)
        self.feature_columns = joblib.load(feature_path)

    def predict_group(self, group, global_classes):
        feature_row = build_meta_feature_row(group, global_classes)

        X_group = pd.DataFrame([feature_row])
        X_group = X_group.reindex(
            columns=self.feature_columns,
            fill_value=0
        )

        predicted_id = self.model.predict(X_group)[0]
        predicted_label = self.label_encoder.inverse_transform(
            [predicted_id]
        )[0]

        probabilities = self.model.predict_proba(X_group)[0]
        meta_confidence = float(max(probabilities))

        return {
            "final_label": predicted_label,
            "meta_confidence": meta_confidence,
            "best_detection": max(
                group,
                key=lambda d: d["confidence"]
            ),
            "agreement_count": len(
                set(d["model"] for d in group)
            ),
            "merged_labels": sorted(
                set(d["label"] for d in group)
            )
        }

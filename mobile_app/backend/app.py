from __future__ import annotations

import itertools
import json
import os
import tempfile
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import yaml
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parents[1]
META_DIR = REPO_ROOT / "meta_classifier"
EVIDENCE_DIR = BASE_DIR / "evidence"

MODEL_SPECS = [
    {
        "id": "member_1",
        "name": "Road Surface Hazards",
        "model_path": REPO_ROOT / "ml_models/member1_walkway_surface/weights/best.pt",
        "config_path": REPO_ROOT / "ml_models/member1_walkway_surface/data.yaml",
    },
    {
        "id": "member_2",
        "name": "Walkway Obstruction Hazards",
        "model_path": REPO_ROOT / "ml_models/member2_obstruction/weights/best.pt",
        "config_path": REPO_ROOT / "ml_models/member2_obstruction/data.yaml",
    },
    {
        "id": "member_3",
        "name": "Road and Drainage Hazards",
        "model_path": REPO_ROOT / "ml_models/member3_drainage/weights/best.pt",
        "config_path": REPO_ROOT / "ml_models/member3_drainage/data.yaml",
    },
    {
        "id": "member_4",
        "name": "Access and Safety Hazards",
        "model_path": REPO_ROOT / "ml_models/member4_access_boundary/weights/best.pt",
        "config_path": REPO_ROOT / "ml_models/member4_access_boundary/data.yaml",
    },
]

CATEGORY_MAP = {
    "pothole": ("road_surface_hazard", "high"),
    "cracked_pavement": ("road_surface_hazard", "medium"),
    "wet_slippery_floor": ("slip_hazard", "medium"),
    "surface_damage": ("road_surface_hazard", "medium"),
    "damaged_sidewalk": ("walkway_hazard", "medium"),
    "obstacle_on_walkway": ("obstruction_hazard", "medium"),
    "construction_debris": ("obstruction_hazard", "medium"),
    "fallen_branch": ("obstruction_hazard", "medium"),
    "traffic_cone": ("temporary_warning_object", "low"),
    "open_drain": ("drainage_hazard", "high"),
    "uncovered_manhole": ("hole_on_road_or_ground", "high"),
    "uneven_pavement": ("road_surface_hazard", "medium"),
    "missing_barricade": ("access_control_hazard", "high"),
    "damaged_warning_sign": ("warning_sign_hazard", "medium"),
    "broken_handrail": ("structural_safety_hazard", "high"),
    "blocked_walkway": ("obstruction_hazard", "medium"),
}

app = FastAPI(title="SafeCampus AI Backend")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def load_class_names(config_path: Path) -> dict[int, str]:
    data = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    names = data.get("names", {})
    if isinstance(names, list):
        return {idx: name for idx, name in enumerate(names)}
    return {int(idx): str(name) for idx, name in names.items()}


MODELS: list[dict[str, Any]] = []
for spec in MODEL_SPECS:
    if not spec["model_path"].exists():
        raise FileNotFoundError(f"Missing model file: {spec['model_path']}")
    if not spec["config_path"].exists():
        raise FileNotFoundError(f"Missing config file: {spec['config_path']}")
    MODELS.append(
        {
            **spec,
            "model": YOLO(str(spec["model_path"])),
            "classes": load_class_names(spec["config_path"]),
        }
    )


META_MODEL = joblib.load(META_DIR / "trained_meta_classifier.pkl")
FEATURE_COLUMNS: list[str] = joblib.load(META_DIR / "feature_columns.joblib")
LABEL_ENCODER = joblib.load(META_DIR / "label_encoder.joblib")


def fallback_recommendation_for(label: str, category: str, severity: str, zone: str) -> str:
    readable_label = label.replace("_", " ")
    if severity == "high":
        return f"Mark the area immediately, restrict access if possible, and report the {readable_label} in {zone} to campus maintenance for urgent action."
    if severity == "medium":
        return f"Record the {readable_label}, warn nearby users, and submit a maintenance report for inspection and repair in {zone}."
    return f"Monitor the {readable_label} in {zone}, keep evidence, and report it if it creates obstruction or safety risk."


def parse_gemini_text(payload: dict[str, Any]) -> str:
    if isinstance(payload.get("output_text"), str):
        return payload["output_text"].strip()

    output = payload.get("output")
    if isinstance(output, list):
        parts: list[str] = []
        for item in output:
            if isinstance(item, dict) and isinstance(item.get("text"), str):
                parts.append(item["text"])
        if parts:
            return " ".join(parts).strip()

    steps = payload.get("steps")
    if isinstance(steps, list):
        parts = []
        for step in steps:
            for item in step.get("output", []) if isinstance(step, dict) else []:
                if isinstance(item, dict) and isinstance(item.get("text"), str):
                    parts.append(item["text"])
        if parts:
            return " ".join(parts).strip()

    candidates = payload.get("candidates")
    if isinstance(candidates, list) and candidates:
        content = candidates[0].get("content", {})
        parts = content.get("parts", []) if isinstance(content, dict) else []
        texts = [part.get("text", "") for part in parts if isinstance(part, dict)]
        return " ".join(texts).strip()

    return ""


def gemini_recommendation_for(label: str, category: str, severity: str, zone: str, confidence: float) -> str | None:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return None

    readable_label = label.replace("_", " ")
    readable_category = category.replace("_", " ")
    prompt = (
        "You are a campus safety assistant. Write one concise maintenance action "
        "for a mobile hazard detection app. Use plain English, be practical, and "
        "do not mention AI uncertainty. Keep it to one or two sentences.\n\n"
        f"Hazard: {readable_label}\n"
        f"Category: {readable_category}\n"
        f"Severity: {severity}\n"
        f"Confidence: {confidence * 100:.1f}%\n"
        f"Campus zone: {zone}\n"
    )
    model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    payload = {
        "systemInstruction": {
            "parts": [
                {
                    "text": (
                        "Generate safety recommendations for campus maintenance reports. "
                        "Avoid medical, legal, or emergency guarantees."
                    )
                }
            ]
        },
        "contents": [
            {
                "parts": [
                    {
                        "text": prompt,
                    }
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.2,
        },
    }
    request = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=12) as response:
            response_payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        details = error.read().decode("utf-8", errors="replace")[:500]
        print(f"Gemini recommendation fallback used: HTTP {error.code} {details}")
        return None
    except (OSError, urllib.error.URLError, json.JSONDecodeError) as error:
        print(f"Gemini recommendation fallback used: {error}")
        return None

    text = parse_gemini_text(response_payload)
    return text or None


def recommendation_for(label: str, category: str, severity: str, zone: str, confidence: float) -> str:
    return (
        gemini_recommendation_for(label, category, severity, zone, confidence)
        or fallback_recommendation_for(label, category, severity, zone)
    )


def bbox_iou(a: list[float], b: list[float]) -> float:
    ax1, ay1, ax2, ay2 = a
    bx1, by1, bx2, by2 = b
    inter_x1 = max(ax1, bx1)
    inter_y1 = max(ay1, by1)
    inter_x2 = min(ax2, bx2)
    inter_y2 = min(ay2, by2)
    inter_w = max(0.0, inter_x2 - inter_x1)
    inter_h = max(0.0, inter_y2 - inter_y1)
    inter_area = inter_w * inter_h
    area_a = max(0.0, ax2 - ax1) * max(0.0, ay2 - ay1)
    area_b = max(0.0, bx2 - bx1) * max(0.0, by2 - by1)
    union = area_a + area_b - inter_area
    return 0.0 if union <= 0 else inter_area / union


def build_meta_features(detections: list[dict[str, Any]]) -> list[float]:
    features: dict[str, float] = {column: 0.0 for column in FEATURE_COLUMNS}
    if not detections:
        return [features[column] for column in FEATURE_COLUMNS]

    confidences = [float(item["confidence"]) for item in detections]
    best_detection = max(detections, key=lambda item: float(item["confidence"]))
    x1, y1, x2, y2 = [float(value) for value in best_detection["bbox"]]
    width = max(0.0, x2 - x1)
    height = max(0.0, y2 - y1)

    ious = [
        bbox_iou(first["bbox"], second["bbox"])
        for first, second in itertools.combinations(detections, 2)
    ]
    vote_counts: dict[str, int] = {}
    for item in detections:
        label = str(item["label"])
        vote_counts[label] = vote_counts.get(label, 0) + 1

    features.update(
        {
            "best_confidence": max(confidences),
            "mean_confidence": float(np.mean(confidences)),
            "min_confidence": min(confidences),
            "agreement_count": float(max(vote_counts.values(), default=0)),
            "detection_count": float(len(detections)),
            "max_iou": max(ious, default=0.0),
            "mean_iou": float(np.mean(ious)) if ious else 0.0,
            "best_box_x1": x1,
            "best_box_y1": y1,
            "best_box_width": width,
            "best_box_height": height,
            "best_box_area": width * height,
        }
    )

    for item in detections:
        member_key = str(item["model_id"]).replace("_", "") + "_detected"
        if member_key in features:
            features[member_key] = 1.0

        vote_key = f"{item['label']}_votes"
        if vote_key in features:
            features[vote_key] += 1.0

    return [features[column] for column in FEATURE_COLUMNS]


def choose_final_detection(detections: list[dict[str, Any]]) -> dict[str, Any] | None:
    if not detections:
        return None

    feature_vector = build_meta_features(detections)
    prediction = META_MODEL.predict([feature_vector])[0]
    predicted_label = str(LABEL_ENCODER.inverse_transform([int(prediction)])[0])

    meta_confidence = None
    if hasattr(META_MODEL, "predict_proba"):
        probabilities = META_MODEL.predict_proba([feature_vector])[0]
        meta_confidence = float(max(probabilities))

    matching = [item for item in detections if item["label"] == predicted_label]
    representative = max(matching or detections, key=lambda item: float(item["confidence"]))
    category, severity = CATEGORY_MAP.get(predicted_label, ("campus_hazard", "medium"))

    return {
        **representative,
        "label": predicted_label,
        "category": category,
        "severity": severity,
        "confidence": round(meta_confidence if meta_confidence is not None else representative["confidence"], 4),
        "yolo_confidence": representative["confidence"],
        "model_id": "meta_classifier",
        "model_name": "Neural Meta-Classifier",
        "source_model_id": representative["model_id"],
        "source_model_name": representative["model_name"],
        "meta_features": {column: value for column, value in zip(FEATURE_COLUMNS, feature_vector)},
    }


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "app": "SafeCampus AI Backend",
        "models_loaded": [model["id"] for model in MODELS],
        "meta_classifier": {
            "loaded": True,
            "features": len(FEATURE_COLUMNS),
            "classes": [str(label) for label in LABEL_ENCODER.classes_],
        },
        "gemini": {
            "configured": bool(os.getenv("GEMINI_API_KEY")),
            "model": os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
        },
    }



@app.post("/evidence")
async def save_evidence(
    image: UploadFile = File(...),
    zone: str = Form("campus_area"),
    result_json: str = Form("{}"),
) -> dict[str, Any]:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    evidence_id = f"evidence_{timestamp}"
    evidence_folder = EVIDENCE_DIR / evidence_id
    evidence_folder.mkdir(parents=True, exist_ok=True)

    suffix = Path(image.filename or "evidence.jpg").suffix or ".jpg"
    image_path = evidence_folder / f"image{suffix}"
    image_path.write_bytes(await image.read())

    try:
        result_payload = json.loads(result_json)
    except json.JSONDecodeError:
        result_payload = {"raw_result": result_json}

    record = {
        "evidence_id": evidence_id,
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "zone": zone,
        "image_file": image_path.name,
        "result": result_payload,
    }
    record_path = evidence_folder / "record.json"
    record_path.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")

    return {
        "saved": True,
        "evidence_id": evidence_id,
        "folder": str(evidence_folder),
        "image_file": str(image_path),
        "record_file": str(record_path),
    }

@app.post("/detect")
async def detect(
    image: UploadFile = File(...),
    zone: str = Form("campus_area"),
    confidence_threshold: float = Form(0.25),
) -> dict[str, Any]:
    suffix = Path(image.filename or "upload.jpg").suffix or ".jpg"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
        temp_path = Path(temp_file.name)
        temp_file.write(await image.read())

    detections: list[dict[str, Any]] = []
    try:
        for model_info in MODELS:
            results = model_info["model"](str(temp_path), conf=confidence_threshold, verbose=False)
            result = results[0]
            for box in result.boxes:
                cls_id = int(box.cls[0].item())
                label = model_info["classes"].get(cls_id, str(cls_id))
                confidence = float(box.conf[0].item())
                x1, y1, x2, y2 = [float(value) for value in box.xyxy[0].tolist()]
                category, severity = CATEGORY_MAP.get(label, ("campus_hazard", "medium"))
                detections.append(
                    {
                        "model_id": model_info["id"],
                        "model_name": model_info["name"],
                        "class_id": cls_id,
                        "label": label,
                        "category": category,
                        "severity": severity,
                        "confidence": round(confidence, 4),
                        "bbox": [round(x1, 2), round(y1, 2), round(x2, 2), round(y2, 2)],
                    }
                )
    finally:
        temp_path.unlink(missing_ok=True)

    final_detection = choose_final_detection(detections)
    if final_detection is None:
        return {
            "detected": False,
            "message": "No campus hazard detected.",
            "zone": zone,
            "detections": [],
            "final": None,
        }

    final = {
        **final_detection,
        "recommendation": recommendation_for(
            final_detection["label"],
            final_detection["category"],
            final_detection["severity"],
            zone,
            final_detection["confidence"],
        ),
    }
    return {
        "detected": True,
        "zone": zone,
        "final": final,
        "detections": detections,
    }







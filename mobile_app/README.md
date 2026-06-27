# SafeCampus AI Mobile App

Flutter client and FastAPI inference backend for the Campus Hazard Detection project.

## Features

- Capture a camera image or select one from the gallery.
- Run all four member YOLO detectors through one backend request.
- Resolve detections with the trained neural meta-classifier.
- Display the final bounding box, class, confidence, severity, and source detections.
- Generate a Gemini maintenance recommendation with local fallback rules.
- Save an evidence image and JSON detection record locally.

## Repository Integration

The backend reuses the model files already stored at the repository root:

- `ml_models/*/weights/best.pt`
- `ml_models/*/data.yaml`
- `meta_classifier/trained_meta_classifier.pkl`
- `meta_classifier/feature_columns.joblib`
- `meta_classifier/label_encoder.joblib`

Model and classifier copies from the submitted ZIP are intentionally not duplicated in this folder.

## Run the Backend

From the repository root:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r mobile_app/backend/requirements.txt
python -m uvicorn app:app --app-dir mobile_app/backend --host 0.0.0.0 --port 8000
```

Set `GEMINI_API_KEY` to enable Gemini recommendations. The default model is `gemini-2.5-flash`; it can be changed through `GEMINI_MODEL`. Without an API key or when the request fails, the backend automatically returns a local safety recommendation.

```powershell
$env:GEMINI_API_KEY="your_api_key"
$env:GEMINI_MODEL="gemini-2.5-flash"
```

The backend exposes `GET /health`, `POST /detect`, and `POST /evidence`.
Saved evidence is written to `mobile_app/backend/evidence/` and is ignored by Git.

## Run the Flutter Client

```powershell
cd mobile_app
flutter pub get
flutter run
```

The client uses `127.0.0.1:8000` in a web browser and `10.0.2.2:8000` in the Android emulator. For a physical phone, replace the host in `lib/main.dart` with the development computer's local network IP address.

## Files Excluded from GitHub

The submitted ZIP also contains local caches and generated data that must not be uploaded:

- `.dart_tool/`, `build/`, `.gradle/`, `.kotlin/`, and IDE metadata
- browser profiles, cookies, login databases, and session data
- `android/local.properties`
- generated evidence and personal test images
- duplicate YOLO and meta-classifier files
- compiled Python cache files

# Mobile App

Place the Flutter or approved mobile app source code in this folder.

## Required Features

- Live camera frame capture.
- YOLO inference through on-device models or a backend inference service.
- Meta-classifier final prediction display.
- Bounding box, final hazard label, confidence score, and severity display.
- LLM-based recommended action.
- Screenshot, timestamp, and detection record saving.

## Integration Notes

If running four YOLO models directly on the phone is too heavy, use a backend service:

```text
Mobile camera frame -> backend API -> YOLO models -> meta-classifier -> LLM recommendation -> app display
```


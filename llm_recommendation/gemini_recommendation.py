import argparse
import json
import os
import urllib.error
import urllib.request


GEMINI_MODEL = "gemini-1.5-flash"


SYSTEM_PROMPT = (
    "You are a campus safety maintenance assistant. Generate one concise, "
    "practical, safety-oriented action for the detected campus hazard. The "
    "action must be relevant to facilities maintenance. Do not suggest that "
    "students repair dangerous hazards themselves. If the hazard may endanger "
    "people, recommend isolating the area and reporting it to the responsible "
    "campus maintenance unit."
)


FALLBACK_ACTIONS = {
    "uncovered_manhole": "Place a temporary barricade, keep pedestrians away, and report the uncovered manhole to campus facilities for urgent repair.",
    "open_drain": "Mark the open drain area, prevent access, and report it to campus facilities for inspection and repair.",
    "pothole": "Mark the pothole, warn road users, and report it to campus facilities for road repair scheduling.",
    "wet_slippery_floor": "Place a wet-floor warning sign, restrict access if needed, and request cleaning staff to dry the area promptly.",
    "broken_handrail": "Warn users to avoid the affected side and report the broken handrail to facilities for urgent inspection and repair.",
    "blocked_walkway": "Clear the walkway if safe, guide pedestrians around the blockage, and report the obstruction to campus maintenance.",
    "obstacle_on_walkway": "Move the obstacle only if safe, keep the walkway clear, and report persistent obstruction to campus maintenance.",
    "damaged_sidewalk": "Mark the damaged sidewalk area, guide pedestrians around it, and report it to campus facilities for repair.",
    "cracked_pavement": "Mark the cracked pavement, monitor pedestrian risk, and report it to campus facilities for repair assessment.",
    "missing_barricade": "Place temporary warning signage, prevent unsafe access, and report the missing barricade to campus facilities immediately.",
    "damaged_warning_sign": "Report the damaged warning sign to campus facilities and place temporary warning information if the area is risky.",
}


def build_prompt(hazard_info):
    return (
        "Detected hazard:\n"
        f"- Hazard class: {hazard_info.get('hazard_class', 'unknown')}\n"
        f"- General category: {hazard_info.get('general_category', 'unknown')}\n"
        f"- Location zone: {hazard_info.get('location_zone', 'unknown')}\n"
        f"- Severity: {hazard_info.get('severity', 'unknown')}\n"
        f"- Confidence: {hazard_info.get('confidence', 'unknown')}\n\n"
        "Return exactly one short recommended maintenance action. Keep it "
        "practical, safety-oriented, and under 30 words."
    )


def fallback_recommendation(hazard_info):
    hazard_class = str(hazard_info.get("hazard_class", "")).lower()
    if hazard_class in FALLBACK_ACTIONS:
        return FALLBACK_ACTIONS[hazard_class]

    severity = str(hazard_info.get("severity", "Medium")).lower()
    if severity == "high":
        return "Isolate the area, warn nearby users, and report the hazard to campus facilities for urgent inspection."

    return "Warn nearby users if needed and report the hazard to campus facilities for inspection and maintenance."


def call_gemini(hazard_info, api_key):
    prompt = build_prompt(hazard_info)
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{GEMINI_MODEL}:generateContent?key={api_key}"
    )
    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": SYSTEM_PROMPT},
                    {"text": prompt},
                ],
            }
        ],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 80,
        },
    }

    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(request, timeout=30) as response:
        data = json.loads(response.read().decode("utf-8"))

    candidates = data.get("candidates", [])
    if not candidates:
        raise RuntimeError("Gemini returned no candidates.")

    parts = candidates[0].get("content", {}).get("parts", [])
    text = " ".join(part.get("text", "") for part in parts).strip()
    if not text:
        raise RuntimeError("Gemini returned an empty recommendation.")

    return text


def recommend_action(hazard_info, use_gemini=True):
    api_key = os.getenv("GEMINI_API_KEY")
    if use_gemini and api_key:
        try:
            return call_gemini(hazard_info, api_key)
        except (urllib.error.URLError, TimeoutError, RuntimeError, KeyError) as exc:
            return fallback_recommendation(hazard_info) + f" (Fallback used: {exc})"

    return fallback_recommendation(hazard_info)


def main():
    parser = argparse.ArgumentParser(
        description="Generate a campus hazard maintenance recommendation."
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to a JSON file containing hazard_class, general_category, location_zone, severity, and confidence.",
    )
    parser.add_argument(
        "--no-gemini",
        action="store_true",
        help="Use the local fallback recommendation rules instead of Gemini.",
    )
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        hazard_info = json.load(f)

    recommendation = recommend_action(
        hazard_info,
        use_gemini=not args.no_gemini,
    )

    print(json.dumps({
        "input": hazard_info,
        "recommended_action": recommendation,
    }, indent=2))


if __name__ == "__main__":
    main()


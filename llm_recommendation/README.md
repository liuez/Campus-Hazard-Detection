# LLM Recommendation

This folder contains the prompt template and API/fallback code for generating recommended maintenance actions from the final meta-classifier result.

## Purpose

The YOLO ensemble and meta-classifier predict the final hazard class. This module converts that structured hazard information into a short, practical, safety-oriented maintenance recommendation for the mobile app.

## Files

- `gemini_recommendation.py`  
  Generates a recommendation using Gemini when `GEMINI_API_KEY` is available. If no key is configured, it uses local fallback rules for demo purposes.

- `prompt_template.md`  
  Prompt design used for the LLM recommendation.

- `sample_hazard_input.json`  
  Example input from the meta-classifier/mobile app pipeline.

- `example_input_output.json`  
  Example recommendation outputs for report and app demonstration.

## Structured Input Example

```json
{
  "hazard_class": "uncovered_manhole",
  "general_category": "Road and walkway hazard",
  "location_zone": "Campus road",
  "severity": "High",
  "confidence": 0.91
}
```

## Run Without Gemini API Key

Use local fallback rules:

```bash
python llm_recommendation/gemini_recommendation.py --input llm_recommendation/sample_hazard_input.json --no-gemini
```

## Run With Gemini API Key

Set the API key as an environment variable. Do not commit the key to GitHub.

PowerShell:

```powershell
$env:GEMINI_API_KEY="your_api_key_here"
python llm_recommendation/gemini_recommendation.py --input llm_recommendation/sample_hazard_input.json
```

## Expected Output Style

The LLM output should be:

- Practical
- Safety-oriented
- Concise
- Relevant to campus maintenance

Example:

```text
Place a temporary barricade, keep pedestrians away, and report the uncovered manhole to campus facilities for urgent repair.
```

## Safety Rule

The recommendation must not ask students to create, inspect, touch, or repair dangerous hazards themselves. Dangerous hazards should be isolated and reported to the responsible campus maintenance unit.

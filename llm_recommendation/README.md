# LLM Recommendation

This folder contains prompt templates or API code for generating recommended maintenance actions.

## Structured Input Example

```json
{
  "hazard_class": "Uncovered manhole",
  "general_category": "Road and walkway hazard",
  "location_zone": "Campus road",
  "severity": "High",
  "confidence": 0.91
}
```

## Expected Output Style

The LLM output should be:

- Practical
- Safety-oriented
- Concise
- Relevant to campus maintenance

Example:

```text
Place a temporary barricade immediately, prevent access, and report to the Facilities Maintenance Unit for urgent repair.
```


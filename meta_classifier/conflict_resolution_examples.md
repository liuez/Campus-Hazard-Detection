# Meta-Classifier Conflict Resolution Examples

These examples describe how overlapping or related YOLO detections can be resolved by the meta-classifier. They are based on the global label mapping and the four member model scopes.

## Example 1: Pothole Agreement

| Field | Value |
|---|---|
| Member 1 prediction | `pothole` |
| Member 3 prediction | `pothole` |
| Relationship | Exact overlap |
| Expected meta-classifier decision | `pothole` |
| Reason | Both models detect the same global class. High IoU and similar confidence should increase agreement confidence. |

## Example 2: Cracked Pavement Agreement

| Field | Value |
|---|---|
| Member 1 prediction | `cracked_pavement` |
| Member 3 prediction | `cracked_pavement` |
| Relationship | Exact overlap |
| Expected meta-classifier decision | `cracked_pavement` |
| Reason | Both models share this class, so overlapping boxes and matching labels should support the final class. |

## Example 3: Wet Floor Overlap

| Field | Value |
|---|---|
| Member 1 prediction | `wet_slippery_floor` |
| Member 2 prediction | `wet_slippery_floor` |
| Relationship | Exact overlap |
| Expected meta-classifier decision | `wet_slippery_floor` |
| Reason | The same class is predicted by two different member models. The meta-classifier can use confidence and box agreement to resolve the final label. |

## Example 4: Walkway Obstruction Context

| Field | Value |
|---|---|
| Member 2 prediction | `obstacle_on_walkway` |
| Member 4 prediction | `blocked_walkway` |
| Relationship | Contextual overlap |
| Expected meta-classifier decision | `blocked_walkway` or `obstacle_on_walkway` depending on confidence, IoU, and zone context |
| Reason | Both labels refer to walkway obstruction, but `blocked_walkway` can indicate a stronger access or safety issue. |

## Example 5: Damaged Sidewalk Overlap

| Field | Value |
|---|---|
| Member 1 prediction | `damaged_sidewalk` |
| Member 4 prediction | `damaged_sidewalk` |
| Relationship | Exact overlap |
| Expected meta-classifier decision | `damaged_sidewalk` |
| Reason | The same global class is detected by two member models. Agreement count and IoU should strengthen the final prediction. |

## Example 6: Ground Hole Generalisation

| Field | Value |
|---|---|
| Member 3 prediction | `open_drain` or `uncovered_manhole` |
| Related global category | Road and walkway hazard |
| Relationship | Parent-child / generalisation |
| Expected meta-classifier decision | Specific hazard label when confidence is high; otherwise related ground-hole class |
| Reason | Ground-hole hazards are visually related but require specific final labels for correct maintenance action. |

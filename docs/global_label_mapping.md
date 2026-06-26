# Global Label Mapping

Use this table to harmonise labels from the four member YOLO models before meta-classification.

| Member | Original YOLO Label | Global Label | Parent Category | Relationship Type | Handling Rule |
|---|---|---|---|---|---|
| Member 1 | `pothole` | Pothole | Road and walkway hazard | generalisation | Keep as a specific class under road or surface damage hazards. |
| Member 1 | `cracked_pavement` | Cracked pavement | Road and walkway hazard | synonym / contextual | Normalise with similar labels such as cracked road or cracked walkway if other models use them. |
| Member 1 | `wet_slippery_floor` | Wet or slippery floor | Road and walkway hazard | exact / synonym | Normalise with wet floor, slippery floor, or wet walkway labels. |
| Member 1 | `surface_damage` | Surface damage | Road and walkway hazard | generalisation | Treat as a parent/general label when the specific damage type is unclear. |
| Member 1 | `damaged_sidewalk` | Damaged sidewalk | Road and walkway hazard | contextual | Use zone/context to distinguish sidewalk damage from road pavement damage. |
| Member 2 | `obstacle_on_walkway` | Obstacle on walkway | Obstruction and sharp object hazard | contextual | Use zone/context to distinguish normal walkway obstruction from emergency-route blockage. |
| Member 2 | `construction_debris` | Construction debris | Obstruction and sharp object hazard | exact / contextual | Keep as a specific obstruction label; severity may increase near walkways or emergency exits. |
| Member 2 | `fallen_branch` | Fallen branch | Obstruction and sharp object hazard | exact / contextual | Keep as a specific obstruction label; context helps distinguish walkway, road, or public facility hazards. |
| Member 2 | `traffic_cone` | Traffic cone | Obstruction and access hazard | contextual | Treat as a hazard only when it blocks access, walkway flow, or emergency routes. |
| Member 2 | `wet_slippery_floor` | Wet or slippery floor | Road and walkway hazard | exact overlap | Overlaps with Member 1 `wet_slippery_floor`; use confidence, IoU, and model reliability in meta-classifier. |
| Member 3 | `open_drain` | Open drain | Road and walkway hazard | generalisation / contextual | Keep as a specific ground-hole hazard; can be grouped under hole on road or ground for recommended actions. |
| Member 3 | `uncovered_manhole` | Uncovered manhole | Road and walkway hazard | generalisation / contextual | Keep as a specific high-severity ground-hole hazard; can be grouped under hole on road or ground. |
| Member 3 | `pothole` | Pothole | Road and walkway hazard | exact overlap | Overlaps with Member 1 `pothole`; use confidence, IoU, and model reliability in meta-classifier. |
| Member 3 | `uneven_pavement` | Uneven pavement | Road and walkway hazard | synonym / contextual | Normalise with similar labels such as uneven floor or surface damage when context supports it. |
| Member 3 | `cracked_pavement` | Cracked pavement | Road and walkway hazard | exact overlap | Overlaps with Member 1 `cracked_pavement`; use confidence, IoU, and model reliability in meta-classifier. |
| Member 4 | `missing_barricade` | Missing barricade | Boundary and access hazard | exact / contextual | Keep as a specific access-control hazard; severity depends on restricted or construction zone context. |
| Member 4 | `damaged_warning_sign` | Damaged warning sign | Boundary and access hazard | exact / contextual | Keep as a specific warning-sign hazard; use location context for severity and LLM recommendation. |
| Member 4 | `broken_handrail` | Broken handrail | Building and structural hazard | exact | Keep as a specific structural safety label. |
| Member 4 | `blocked_walkway` | Blocked walkway | Obstruction and access hazard | contextual | Contextually overlaps with Member 2 `obstacle_on_walkway`; use zone/context and IoU agreement for final decision. |
| Member 4 | `damaged_sidewalk` | Damaged sidewalk | Road and walkway hazard | exact overlap | Overlaps with Member 1 `damaged_sidewalk`; use confidence, IoU, and model reliability in meta-classifier. |

## Relationship Definitions

- Exact overlap: two or more models detect the same class.
- Synonym: labels use different words but describe the same or very similar hazard.
- Generalisation: one label is broader than another, such as road hole covering pothole, open drain, and uncovered manhole.
- Contextual overlap: the final meaning depends on location, such as obstacle on walkway becoming blocked fire escape in an emergency route.

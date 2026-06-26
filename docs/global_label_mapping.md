# Global Label Mapping

Use this table to harmonise labels from the four member YOLO models before meta-classification.

| Member | Original YOLO Label | Global Label | Parent Category | Relationship Type | Handling Rule |
|---|---|---|---|---|---|
| Member 1 | `pothole` | Pothole | Road and walkway hazard | generalisation | Keep as a specific class under road or surface damage hazards. |
| Member 1 | `cracked_pavement` | Cracked pavement | Road and walkway hazard | synonym / contextual | Normalise with similar labels such as cracked road or cracked walkway if other models use them. |
| Member 1 | `wet_slippery_floor` | Wet or slippery floor | Road and walkway hazard | exact / synonym | Normalise with wet floor, slippery floor, or wet walkway labels. |
| Member 1 | `surface_damage` | Surface damage | Road and walkway hazard | generalisation | Treat as a parent/general label when the specific damage type is unclear. |
| Member 1 | `damaged_sidewalk` | Damaged sidewalk | Road and walkway hazard | contextual | Use zone/context to distinguish sidewalk damage from road pavement damage. |
| Member 2 | To be filled | To be filled | To be filled | exact / synonym / generalisation / contextual | To be filled |
| Member 3 | To be filled | To be filled | To be filled | exact / synonym / generalisation / contextual | To be filled |
| Member 4 | To be filled | To be filled | To be filled | exact / synonym / generalisation / contextual | To be filled |

## Relationship Definitions

- Exact overlap: two or more models detect the same class.
- Synonym: labels use different words but describe the same or very similar hazard.
- Generalisation: one label is broader than another, such as road hole covering pothole, open drain, and uncovered manhole.
- Contextual overlap: the final meaning depends on location, such as obstacle on walkway becoming blocked fire escape in an emergency route.

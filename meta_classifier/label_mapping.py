# Global label mapping for all four YOLO members

GLOBAL_CLASSES = [
    "pothole",
    "cracked_pavement",
    "wet_slippery_floor",
    "surface_damage",
    "damaged_sidewalk",
    "obstacle_on_walkway",
    "construction_debris",
    "fallen_branch",
    "traffic_cone",
    "open_drain",
    "uncovered_manhole",
    "uneven_pavement",
    "missing_barricade",
    "damaged_warning_sign",
    "broken_handrail",
    "blocked_walkway"
]

GLOBAL_CLASS_INDEX = {
    label: idx for idx, label in enumerate(GLOBAL_CLASSES)
}

MEMBER_LABEL_MAPPING = {
    "member1": {
        0: "pothole",
        1: "cracked_pavement",
        2: "wet_slippery_floor",
        3: "surface_damage",
        4: "damaged_sidewalk"
    },
    "member2": {
        0: "obstacle_on_walkway",
        1: "construction_debris",
        2: "fallen_branch",
        3: "traffic_cone",
        4: "wet_slippery_floor"
    },
    "member3": {
        0: "open_drain",
        1: "uncovered_manhole",
        2: "pothole",
        3: "uneven_pavement",
        4: "cracked_pavement"
    },
    "member4": {
        0: "missing_barricade",
        1: "damaged_warning_sign",
        2: "broken_handrail",
        3: "blocked_walkway",
        4: "damaged_sidewalk"
    }
}

class_name ContentDistribution
extends Resource

@export var distribution_id: String = "default"
@export var content_categories: Dictionary = { # Define all placeable content entities dynamically
    "obstacles": {"base_ratio_weight": 2, "allowed_entities": ["Log"], "placement_tag": "obstacle_marker"},
    "boosts": {"base_ratio_weight": 1, "allowed_entities": ["SpeedPad"], "placement_tag": "boost_marker"},
    "collectibles": {"base_ratio_weight": 1, "allowed_entities": ["Coin"], "placement_tag": "any"}, # "any" marker tag means less specific
     # Add other categories (narrative_triggers, scoring_objects) here as needed, even if initially empty allowed_entities
}
@export var placement_constraints: Dictionary = { # Rules governing placement
    "max_per_chunk": {"obstacles": 5, "boosts": 2, "collectibles": 10}, # Per-category limits
    "minimum_spacing": { # Per-category and global minimum distances
        "obstacle": {"distance": 50}, "boost": {"distance": 100}, "collectible": {"distance": 10},
        "any_content": {"distance": 5} # Overall minimum gap
    },
    "disallowed_patterns": ["BOOST_OBSTACLE_BOOST"], # Sequence rules (may need enhancement for categories)
    "pacing_rules": {} # Placeholder for future complex pacing logic (e.g., rest periods, guarantees)
}
@export var difficulty_scaling: Dictionary = { # How rules change based on difficulty/flow context
    "flow_state": { # Keys: FlowState enum names (e.g., "MID")
        "MID": {"density_multiplier": {"obstacles": 1.2}, "allowed_entities": {"obstacles": ["+Rock"]}}, # '+' adds entity
    },
    "global_difficulty": { # Keys: StageConfig.target_difficulty (e.g., "hard")
        "hard": {"ratio_weights": {"obstacles": 3}, "max_per_chunk": {"obstacles": 7}}
    }
}

func validate() -> bool:
    var is_valid = true
    if distribution_id.is_empty(): push_error("ContentDistribution: Missing 'distribution_id'"); is_valid = false
    if content_categories.is_empty(): push_error("ContentDistribution '%s': 'content_categories' cannot be empty" % distribution_id); is_valid = false
    
    # Deep validation for content_categories
    for category_name in content_categories.keys():
        var category = content_categories[category_name]
        if not category.has("base_ratio_weight"):
            push_warning("ContentDistribution '%s': Category '%s' missing 'base_ratio_weight', using 1.0" % [distribution_id, category_name])
            category["base_ratio_weight"] = 1.0
        if not category.has("allowed_entities") or not category.allowed_entities is Array:
            push_warning("ContentDistribution '%s': Category '%s' missing or invalid 'allowed_entities', using empty array" % [distribution_id, category_name])
            category["allowed_entities"] = []
        if not category.has("placement_tag"):
            push_warning("ContentDistribution '%s': Category '%s' missing 'placement_tag', using 'any'" % [distribution_id, category_name])
            category["placement_tag"] = "any"
    
    # Validate placement_constraints
    if not placement_constraints.has("max_per_chunk"):
        push_warning("ContentDistribution '%s': Missing 'max_per_chunk' in placement_constraints, using defaults" % distribution_id)
        placement_constraints["max_per_chunk"] = {}
    
    if not placement_constraints.has("minimum_spacing"):
        push_warning("ContentDistribution '%s': Missing 'minimum_spacing' in placement_constraints, using defaults" % distribution_id)
        placement_constraints["minimum_spacing"] = {"any_content": {"distance": 5}}
    
    # Ensure all categories in content_categories have corresponding entries in max_per_chunk
    for category_name in content_categories.keys():
        if not placement_constraints["max_per_chunk"].has(category_name):
            push_warning("ContentDistribution '%s': No max_per_chunk defined for category '%s', using 5" % [distribution_id, category_name])
            placement_constraints["max_per_chunk"][category_name] = 5
    
    # Validate difficulty_scaling
    if not difficulty_scaling.has("flow_state"):
        push_warning("ContentDistribution '%s': Missing 'flow_state' in difficulty_scaling, using empty dictionary" % distribution_id)
        difficulty_scaling["flow_state"] = {}
    
    if not difficulty_scaling.has("global_difficulty"):
        push_warning("ContentDistribution '%s': Missing 'global_difficulty' in difficulty_scaling, using empty dictionary" % distribution_id)
        difficulty_scaling["global_difficulty"] = {}
    
    return is_valid

const DEFAULT_RESOURCE_PATH = "res://resources/stage/content_distributions/default_distribution.tres"
static func get_default_resource() -> ContentDistribution:
    var default_res = load(DEFAULT_RESOURCE_PATH)
    if default_res is ContentDistribution and default_res.validate(): return default_res
    push_error("Failed to load or validate default ContentDistribution resource at: " + DEFAULT_RESOURCE_PATH)
    var fallback = ContentDistribution.new(); fallback.distribution_id = "emergency_default_distribution"; fallback.validate(); return fallback

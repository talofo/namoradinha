class_name StageCompositionConfig
extends Resource

@export var id: String = "default_stage"
@export var target_difficulty: String = "low" # E.g., "low", "medium", "hard"
@export var flow_profile: Array[String] = ["low", "mid", "low"] # Sequence of flow states (e.g., "low", "rising", "mid", "high", "falling")
@export var chunk_count_estimate: int = 10 # Estimation for fallback length/progress
@export var theme: String = "forest"
@export var launch_event_type: String = "player_start" # For Story Mode start. E.g., "player_start", "npc_kick", "automatic"
@export var story_end_condition: Dictionary = { # For Story Mode end.
    "type": "distance", # "distance" | "event"
    "value": 1000.0 # Required if type="distance"
    # --- OR ---
    # "type": "event",
    # "event_name": "SpecificEventName", # Required if type="event"
    # "trigger_distance": 950.0 # Optional: Min distance before event can trigger end
}
@export var next_stage_logic: Dictionary = {} # For Arcade Mode transitions. Structure TBD based on logic needed (e.g., {"mode": "random_theme", "theme": "Volcano"})
@export var mandatory_events: Array[Dictionary] = [] # Scripted events/chunks for Story Mode.
    # Example: { "type": "chunk", "chunk_id": "BossChunk01", "trigger_distance": 1200.0 }
    # Example: { "type": "signal_event", "event_name": "NarrativeBeat1", "trigger_distance": 800.0 }
@export var unlock_condition: String = "" # Placeholder for progression gating
@export var chunk_selection: Dictionary = { # Rules for procedural chunk selection
    "allowed_types": ["straight_easy", "curve_left_easy"], # List of ChunkDefinition.chunk_type
    "theme_tags": ["forest", "standard"] # List of tags to match ChunkDefinition.theme_tags
}
@export var content_distribution_id: String = "default" # ID linking to a ContentDistribution resource
@export var debug_markers: bool = false # Enable debug visualizations

# Calculates effective length for flow mapping etc.
func get_effective_length() -> float:
    if story_end_condition.has("type"):
        if story_end_condition.type == "distance" and story_end_condition.has("value"):
            return max(1.0, float(story_end_condition.value))
        if story_end_condition.type == "event" and story_end_condition.has("trigger_distance"):
            return max(1.0, float(story_end_condition.trigger_distance))
    return max(1.0, float(chunk_count_estimate * 100.0)) # Fallback using estimate (assume 100 length per chunk)

func validate() -> bool:
    var is_valid = true
    if id.is_empty(): push_error("StageCompositionConfig: Missing 'id'"); is_valid = false
    if theme.is_empty(): push_error("StageCompositionConfig '%s': Missing 'theme'" % id); is_valid = false
    if flow_profile.is_empty(): push_warning("StageCompositionConfig '%s': Empty flow profile, using default" % id); flow_profile = ["low", "mid", "low"]
    if not story_end_condition.has("type"): push_error("StageCompositionConfig '%s': Missing 'type' in 'story_end_condition'" % id); is_valid = false
    # Add detailed validation for story_end_condition structure based on type
    if story_end_condition.has("type"):
        if story_end_condition.type == "distance" and not story_end_condition.has("value"):
            push_error("StageCompositionConfig '%s': Missing 'value' in 'story_end_condition' for type 'distance'" % id)
            is_valid = false
        elif story_end_condition.type == "event" and not story_end_condition.has("event_name"):
            push_error("StageCompositionConfig '%s': Missing 'event_name' in 'story_end_condition' for type 'event'" % id)
            is_valid = false
    
    # Add validation for mandatory_events structure
    for i in range(mandatory_events.size()):
        var event = mandatory_events[i]
        if not event.has("type"):
            push_error("StageCompositionConfig '%s': Mandatory event at index %d missing 'type'" % [id, i])
            is_valid = false
        elif not event.has("trigger_distance"):
            push_error("StageCompositionConfig '%s': Mandatory event at index %d missing 'trigger_distance'" % [id, i])
            is_valid = false
        elif event.type == "chunk" and not event.has("chunk_id"):
            push_error("StageCompositionConfig '%s': Mandatory event at index %d of type 'chunk' missing 'chunk_id'" % [id, i])
            is_valid = false
        elif event.type == "signal_event" and not event.has("event_name"):
            push_error("StageCompositionConfig '%s': Mandatory event at index %d of type 'signal_event' missing 'event_name'" % [id, i])
            is_valid = false
    
    # Validate content_distribution_id is not empty
    if content_distribution_id.is_empty():
        push_warning("StageCompositionConfig '%s': Empty 'content_distribution_id', using 'default'" % id)
        content_distribution_id = "default"
    
    return is_valid

const DEFAULT_RESOURCE_PATH = "res://resources/stage/configs/default_stage.tres"
static func get_default_resource() -> StageCompositionConfig:
    var default_res = load(DEFAULT_RESOURCE_PATH)
    if default_res is StageCompositionConfig and default_res.validate(): return default_res
    push_error("Failed to load or validate default StageCompositionConfig resource at: " + DEFAULT_RESOURCE_PATH)
    var fallback = StageCompositionConfig.new(); fallback.id = "emergency_default_stage"; fallback.validate(); return fallback

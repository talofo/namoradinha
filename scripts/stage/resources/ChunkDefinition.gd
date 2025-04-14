class_name ChunkDefinition
extends Resource

@export var chunk_id: String = "chunk_default"
@export var chunk_type: String = "straight" # Categorization (e.g., "straight", "curve_left", "jump_medium")
@export var layout_markers: Array[Dictionary] = [] # Define positions for content placement
    # Recommended Structure: {"name": "MarkerA", "position": Vector3(10,0,0), "intended_category": "obstacle", "tags": ["narrow"]}
@export var theme_tags: Array[String] = ["standard"] # For matching StageConfig.chunk_selection.theme_tags
@export var difficulty_rating: float = 1.0 # Base difficulty score for filtering
@export var length: float = 100.0 # Physical length, crucial for placement and trigger distances
@export var transition_chunk: bool = false # Flags chunk suitable for biome/theme blending

func validate() -> bool:
    var is_valid = true
    if chunk_id.is_empty(): push_error("ChunkDefinition: Missing 'chunk_id'"); is_valid = false
    if chunk_type.is_empty(): push_warning("ChunkDefinition '%s': Empty 'chunk_type', using 'straight'" % chunk_id); chunk_type = "straight"
    if length <= 0: push_warning("ChunkDefinition '%s': Invalid length (%f), using 100.0" % [chunk_id, length]); length = 100.0
    
    # Add validation for layout_markers structure
    for i in range(layout_markers.size()):
        var marker = layout_markers[i]
        if not marker.has("name"):
            push_warning("ChunkDefinition '%s': Layout marker at index %d missing 'name'" % [chunk_id, i])
        if not marker.has("position"):
            push_error("ChunkDefinition '%s': Layout marker at index %d missing 'position'" % [chunk_id, i])
            is_valid = false
        elif not marker.position is Vector3:
            push_error("ChunkDefinition '%s': Layout marker '%s' has invalid position type (not Vector3)" % [chunk_id, marker.get("name", "unnamed")])
            is_valid = false
    
    return is_valid

const DEFAULT_RESOURCE_PATH = "res://resources/stage/chunks/default_chunk.tres"
static func get_default_resource() -> ChunkDefinition:
    var default_res = load(DEFAULT_RESOURCE_PATH)
    if default_res is ChunkDefinition and default_res.validate(): return default_res
    push_error("Failed to load or validate default ChunkDefinition resource at: " + DEFAULT_RESOURCE_PATH)
    var fallback = ChunkDefinition.new(); fallback.chunk_id = "emergency_default_chunk"; fallback.validate(); return fallback

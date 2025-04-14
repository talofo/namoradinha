class_name ChunkManagementSystem
extends Node

# Import required classes
# In Godot 4.4+, classes with class_name are globally available

# Current stage configuration
var _current_config: StageCompositionConfig = null

# Flow controller reference
var _flow_controller: FlowAndDifficultyController = null

# Chunk tracking
var _active_chunks: Array = [] # Array of {chunk_definition, start_position, end_position}
var _next_chunk_position: Vector3 = Vector3.ZERO
var _player_position: Vector3 = Vector3.ZERO
var _last_mandatory_event_index: int = -1

# Preloading
var _preload_distance: float = 300.0 # Distance ahead to preload chunks
var _cleanup_distance: float = 200.0 # Distance behind to keep chunks

# Debug flag
var _debug_enabled: bool = false

func _ready():
    pass

# Initialize with stage configuration and flow controller
func initialize(config: StageCompositionConfig, flow_controller: FlowAndDifficultyController) -> void:
    _current_config = config
    _flow_controller = flow_controller
    _active_chunks.clear()
    _next_chunk_position = Vector3.ZERO
    _player_position = Vector3.ZERO
    _last_mandatory_event_index = -1
    
    if _debug_enabled:
        print("ChunkManagementSystem: Initialized with config '%s'" % config.id)

# Generate initial chunks to start the stage
func generate_initial_chunks(count: int = 3) -> void:
    if not _current_config:
        push_error("ChunkManagementSystem: No stage config set")
        return
    
    if _debug_enabled:
        print("ChunkManagementSystem: Generating initial %d chunks" % count)
    
    # Generate first chunks
    for i in range(count):
        generate_next_chunk()

# Generate the next chunk
func generate_next_chunk() -> void:
    if not _current_config:
        push_error("ChunkManagementSystem: No stage config set")
        return
    
    # Get current distance
    var current_distance = _player_position.z
    
    # Select next chunk
    var chunk_definition = select_next_chunk(current_distance)
    if not chunk_definition:
        push_error("ChunkManagementSystem: Failed to select next chunk")
        return
    
    # Calculate chunk end position
    var chunk_end_position = _next_chunk_position + Vector3(0, 0, chunk_definition.length)
    
    # Add to active chunks
    _active_chunks.append({
        "chunk_definition": chunk_definition,
        "start_position": _next_chunk_position,
        "end_position": chunk_end_position
    })
    
    # Emit signal to instantiate the chunk
    GlobalSignals.request_chunk_instantiation.emit(chunk_definition, _next_chunk_position)
    
    # Emit analytics event
    GlobalSignals.analytics_event.emit({
        "event_type": "chunk_generated",
        "chunk_id": chunk_definition.chunk_id,
        "chunk_type": chunk_definition.chunk_type,
        "position": _next_chunk_position,
        "is_transition": chunk_definition.transition_chunk,
        "difficulty_rating": chunk_definition.difficulty_rating
    })
    
    if _debug_enabled:
        print("ChunkManagementSystem: Generated chunk '%s' at position %s" % [chunk_definition.chunk_id, str(_next_chunk_position)])
    
    # Update next chunk position
    _next_chunk_position = chunk_end_position

# Select the next chunk based on current context
func select_next_chunk(current_distance: float) -> ChunkDefinition:
    if not _current_config or not _flow_controller:
        push_error("ChunkManagementSystem: Missing config or flow controller")
        return null
    
    # Check for mandatory events first
    var mandatory_chunk = _check_mandatory_events(current_distance)
    if mandatory_chunk:
        return mandatory_chunk
    
    # Get current flow state and theme
    var flow_state = _flow_controller.get_current_flow_state()
    var theme = _current_config.theme
    
    # Get allowed chunk types and theme tags from config
    var allowed_types = _current_config.chunk_selection.get("allowed_types", [])
    var theme_tags = _current_config.chunk_selection.get("theme_tags", [])
    
    # Find all matching chunks
    var matching_chunks = _find_matching_chunks(allowed_types, theme_tags, theme)
    
    # If no matching chunks, try fallbacks
    if matching_chunks.is_empty():
        # Try with just theme tags
        matching_chunks = _find_matching_chunks([], theme_tags, theme)
        
        if matching_chunks.is_empty():
            # Try with just theme
            matching_chunks = _find_matching_chunks([], [], theme)
            
            if matching_chunks.is_empty():
                # Last resort: use default chunk
                push_warning("ChunkManagementSystem: No matching chunks found, using default")
                return ChunkDefinition.get_default_resource()
    
    # Select a random chunk from matching chunks
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var index = rng.randi() % matching_chunks.size()
    
    # Emit analytics event for chunk selection
    GlobalSignals.analytics_event.emit({
        "event_type": "chunk_selected",
        "selection_method": "procedural",
        "flow_state": FlowAndDifficultyController.FlowState.keys()[flow_state],
        "matching_chunks_count": matching_chunks.size(),
        "selected_chunk": matching_chunks[index].chunk_id
    })
    
    return matching_chunks[index]

# Check for mandatory events that should trigger at the current distance
func _check_mandatory_events(current_distance: float) -> ChunkDefinition:
    if not _current_config or _current_config.mandatory_events.is_empty():
        return null
    
    # Look ahead to find events that should trigger soon
    var look_ahead_distance = _preload_distance
    
    # Check each mandatory event
    for i in range(_last_mandatory_event_index + 1, _current_config.mandatory_events.size()):
        var event = _current_config.mandatory_events[i]
        
        # Skip if not a chunk event
        if event.get("type") != "chunk":
            continue
        
        # Check if this event should trigger now
        var trigger_distance = event.get("trigger_distance", 0.0)
        if current_distance <= trigger_distance and trigger_distance <= current_distance + look_ahead_distance:
            # Found a mandatory chunk to place
            var chunk_id = event.get("chunk_id", "")
            if chunk_id.is_empty():
                push_warning("ChunkManagementSystem: Mandatory event at index %d missing chunk_id" % i)
                continue
            
            # Load the chunk
            var chunk = _load_chunk_definition(chunk_id)
            if not chunk:
                push_error("ChunkManagementSystem: Failed to load mandatory chunk '%s'" % chunk_id)
                continue
            
            # Update last mandatory event index
            _last_mandatory_event_index = i
            
            # Emit analytics event
            GlobalSignals.analytics_event.emit({
                "event_type": "mandatory_chunk_triggered",
                "chunk_id": chunk_id,
                "trigger_distance": trigger_distance,
                "actual_distance": current_distance,
                "event_index": i
            })
            
            if _debug_enabled:
                print("ChunkManagementSystem: Triggered mandatory chunk '%s' at distance %f" % [chunk_id, current_distance])
            
            return chunk
        
        # Check for signal events that should trigger
        elif event.get("type") == "signal_event" and current_distance <= trigger_distance and trigger_distance <= current_distance + look_ahead_distance:
            var event_name = event.get("event_name", "")
            if event_name.is_empty():
                push_warning("ChunkManagementSystem: Mandatory signal event at index %d missing event_name" % i)
                continue
            
            # Emit the gameplay event
            var event_data = event.duplicate()
            event_data.erase("type")
            event_data.erase("event_name")
            event_data.erase("trigger_distance")
            event_data["distance"] = current_distance
            
            GlobalSignals.gameplay_event_triggered.emit(event_name, event_data)
            
            # Emit analytics event
            GlobalSignals.analytics_event.emit({
                "event_type": "mandatory_signal_triggered",
                "event_name": event_name,
                "trigger_distance": trigger_distance,
                "actual_distance": current_distance,
                "event_index": i
            })
            
            # Update last mandatory event index
            _last_mandatory_event_index = i
            
            if _debug_enabled:
                print("ChunkManagementSystem: Triggered mandatory signal event '%s' at distance %f" % [event_name, current_distance])
    
    # No mandatory events to trigger
    return null

# Find chunks matching the given criteria
func _find_matching_chunks(allowed_types: Array, theme_tags: Array, theme: String) -> Array:
    var matching_chunks = []
    
    # Get all chunk resources
    var chunks_dir = "res://resources/stage/chunks/"
    var dir = DirAccess.open(chunks_dir)
    
    if not dir:
        push_error("ChunkManagementSystem: Failed to open chunks directory")
        return matching_chunks
    
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".tres"):
            var chunk_path = chunks_dir + file_name
            var chunk = load(chunk_path)
            
            if chunk is ChunkDefinition:
                # Check if chunk matches criteria
                var type_match = allowed_types.is_empty() or allowed_types.has(chunk.chunk_type)
                
                var tag_match = theme_tags.is_empty()
                if not tag_match:
                    for tag in theme_tags:
                        if chunk.theme_tags.has(tag):
                            tag_match = true
                            break
                
                if type_match and tag_match:
                    matching_chunks.append(chunk)
        
        file_name = dir.get_next()
    
    dir.list_dir_end()
    
    return matching_chunks

# Load a specific chunk definition by ID
func _load_chunk_definition(chunk_id: String) -> ChunkDefinition:
    # Try to load from path
    var resource_path = "res://resources/stage/chunks/%s.tres" % chunk_id
    
    if ResourceLoader.exists(resource_path):
        var resource = load(resource_path)
        if resource is ChunkDefinition:
            if resource.validate():
                return resource
            else:
                push_warning("ChunkManagementSystem: Validation failed for '%s'" % resource_path)
        else:
            push_error("ChunkManagementSystem: Resource at '%s' is not a ChunkDefinition" % resource_path)
    else:
        push_warning("ChunkManagementSystem: Chunk not found at '%s'" % resource_path)
    
    # Try default path
    return ChunkDefinition.get_default_resource()

# Update player position and manage chunks
func update_player_position(position: Vector3) -> void:
    _player_position = position
    
    # Check if we need to preload more chunks
    var furthest_chunk_end = _get_furthest_chunk_end()
    if furthest_chunk_end.z - position.z < _preload_distance:
        generate_next_chunk()
    
    # Clean up distant chunks
    cleanup_distant_chunks()

# Get the end position of the furthest chunk
func _get_furthest_chunk_end() -> Vector3:
    if _active_chunks.is_empty():
        return Vector3.ZERO
    
    var furthest_end = _active_chunks[0].end_position
    for chunk_data in _active_chunks:
        if chunk_data.end_position.z > furthest_end.z:
            furthest_end = chunk_data.end_position
    
    return furthest_end

# Clean up chunks that are far behind the player
func cleanup_distant_chunks() -> void:
    var chunks_to_remove = []
    
    for i in range(_active_chunks.size()):
        var chunk_data = _active_chunks[i]
        if _player_position.z - chunk_data.end_position.z > _cleanup_distance:
            chunks_to_remove.append(i)
    
    # Remove from end to start to avoid index issues
    chunks_to_remove.sort()
    chunks_to_remove.reverse()
    
    for i in chunks_to_remove:
        if _debug_enabled:
            print("ChunkManagementSystem: Cleaning up chunk '%s'" % _active_chunks[i].chunk_definition.chunk_id)
        _active_chunks.remove_at(i)

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
    _debug_enabled = enabled

# Set the preload and cleanup distances
func set_streaming_distances(preload_distance: float, cleanup_distance: float) -> void:
    _preload_distance = preload_distance
    _cleanup_distance = cleanup_distance
    
    if _debug_enabled:
        print("ChunkManagementSystem: Set preload distance to %f, cleanup distance to %f" % 
              [preload_distance, cleanup_distance])

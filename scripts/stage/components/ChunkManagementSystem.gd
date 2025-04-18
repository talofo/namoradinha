class_name ChunkManagementSystem
extends Node

# Import required classes
# In Godot 4.4+, classes with class_name are globally available
# Using ChunkResourceLoaderClass for loading chunks to avoid name conflict with global class
const ChunkResourceLoaderClass = preload("res://scripts/stage/resources/ChunkResourceLoader.gd")

# Current stage configuration
var _current_config: StageCompositionConfig = null

# Flow controller reference
var _flow_controller: FlowAndDifficultyController = null

# Content distribution system reference
var _content_distribution_system: ContentDistributionSystem = null

# Chunk resource loader
var _chunk_loader: ChunkResourceLoaderClass = null

# Chunk tracking
var _active_chunks: Array = [] # Array of {chunk_definition, start_position, end_position}
var _next_chunk_position: Vector2 = Vector2.ZERO
var _player_position: Vector2 = Vector2.ZERO
var _last_mandatory_event_index: int = -1

# Preloading
var _preload_distance: float = 300.0 # Distance ahead to preload chunks
var _cleanup_distance: float = 200.0 # Distance behind to keep chunks

# Debug flag
var _debug_enabled: bool = false

func _ready():
    # Initialize chunk loader
    _chunk_loader = ChunkResourceLoaderClass.new()

# Initialize with stage configuration, flow controller, and content distribution system
func initialize(config: StageCompositionConfig, flow_controller: FlowAndDifficultyController, content_distribution_system: ContentDistributionSystem) -> void:
    _current_config = config
    _flow_controller = flow_controller
    _content_distribution_system = content_distribution_system
    _active_chunks.clear()
    _next_chunk_position = Vector2.ZERO
    _player_position = Vector2.ZERO
    _last_mandatory_event_index = -1
    
    # Set debug mode on chunk loader
    _chunk_loader.set_debug_enabled(_debug_enabled)
    
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
    var current_distance = _player_position.y
    
    # Select next chunk
    var chunk_definition = select_next_chunk(current_distance)
    if not chunk_definition:
        push_error("ChunkManagementSystem: Failed to select next chunk")
        return
        
    # Trigger content distribution for the selected chunk
    if _content_distribution_system:
        # Determine the correct distribution_id (likely from _current_config)
        var distribution_id = _current_config.content_distribution_id if _current_config else "default" 
        _content_distribution_system.distribute_content_for_chunk(chunk_definition, distribution_id)
    else:
        push_warning("ChunkManagementSystem: ContentDistributionSystem not set, cannot distribute content.")
        
    # Calculate chunk end position
    var chunk_end_position = _next_chunk_position + Vector2(0, chunk_definition.length)
    
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
func _find_matching_chunks(allowed_types: Array, theme_tags: Array, _theme: String) -> Array:
    # Use the chunk loader to find matching chunks
    return _chunk_loader.find_matching_chunks(allowed_types, theme_tags)

# Load a specific chunk definition by ID
func _load_chunk_definition(chunk_id: String) -> ChunkDefinition:
    # Use the chunk loader to load the chunk
    return _chunk_loader.load_chunk_by_id(chunk_id)

# Update player position and manage chunks
func update_player_position(position: Vector2) -> void:
    _player_position = position
    
    # Check if we need to preload more chunks
    var furthest_chunk_end = _get_furthest_chunk_end()
    if furthest_chunk_end.y - position.y < _preload_distance:
        generate_next_chunk()
    
    # Clean up distant chunks
    cleanup_distant_chunks()

# Get the end position of the furthest chunk
func _get_furthest_chunk_end() -> Vector2:
    if _active_chunks.is_empty():
        return Vector2.ZERO
    
    var furthest_end = _active_chunks[0].end_position
    for chunk_data in _active_chunks:
        if chunk_data.end_position.y > furthest_end.y:
            furthest_end = chunk_data.end_position
    
    return furthest_end

# Clean up chunks that are far behind the player
func cleanup_distant_chunks() -> void:
    var chunks_to_remove = []
    
    for i in range(_active_chunks.size()):
        var chunk_data = _active_chunks[i]
        if _player_position.y - chunk_data.end_position.y > _cleanup_distance:
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
    if _chunk_loader:
        _chunk_loader.set_debug_enabled(enabled)

# Set the preload and cleanup distances
func set_streaming_distances(preload_distance: float, cleanup_distance: float) -> void:
    _preload_distance = preload_distance
    _cleanup_distance = cleanup_distance
    
    if _debug_enabled:
        print("ChunkManagementSystem: Set preload distance to %f, cleanup distance to %f" % 
              [preload_distance, cleanup_distance])

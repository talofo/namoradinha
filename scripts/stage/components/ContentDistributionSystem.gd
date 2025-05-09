class_name ContentDistributionSystem
extends Node

# Import required classes
# In Godot 4.4+, classes with class_name are globally available

# This class handles the distribution of content entities (obstacles, collectibles, etc.)
# within chunks based on content distribution rules and flow state.

# Current distribution strategy
var _distribution_strategy: IContentDistributionStrategy

# Flow controller reference
var _flow_controller: FlowAndDifficultyController

# Content placement history for context
var _placement_history: Array = []

# Maximum history size to prevent memory issues
const MAX_HISTORY_SIZE = 100

# Debug flag
var _debug_enabled: bool = true

func _ready():
    # Set default strategy
    _distribution_strategy = WeightedRandomStrategy.new()

# Initialize with flow controller
func initialize(flow_controller: FlowAndDifficultyController) -> void:
    _flow_controller = flow_controller
    if _debug_enabled:
        print("ContentDistributionSystem: Initialized with flow controller")
        _distribution_strategy.set_debug_enabled(true)

# Set the distribution strategy
func set_distribution_strategy(strategy_name: String) -> bool:
    match strategy_name:
        "weighted_random":
            _distribution_strategy = WeightedRandomStrategy.new()
            if _debug_enabled:
                _distribution_strategy.set_debug_enabled(true)
                print("ContentDistributionSystem: Set strategy to WeightedRandomStrategy")
            return true
        # Add other strategies here as they are implemented
        _:
            push_warning("ContentDistributionSystem: Unknown strategy '%s', using default" % strategy_name)
            _distribution_strategy = WeightedRandomStrategy.new()
            if _debug_enabled:
                _distribution_strategy.set_debug_enabled(true)
            return false

# Distribute content for a chunk
func distribute_content_for_chunk(chunk_definition: ChunkDefinition, distribution_id: String) -> void:
    if not _flow_controller:
        push_error("ContentDistributionSystem: Flow controller not initialized")
        return
    
    # Load content distribution rules
    var content_rules = _load_content_distribution(distribution_id)
    if not content_rules:
        push_error("ContentDistributionSystem: Failed to load content distribution '%s'" % distribution_id)
        return
    
    # Get current flow state and difficulty
    var flow_state = _flow_controller.get_current_flow_state()
    var difficulty = _flow_controller.get_current_difficulty()
    
    if _debug_enabled:
        print("ContentDistributionSystem: Distributing content for chunk '%s' with distribution '%s'" % 
              [chunk_definition.chunk_id, distribution_id])
        print("ContentDistributionSystem: Current flow state: %s, difficulty: %s" % 
              [FlowAndDifficultyController.FlowState.keys()[flow_state], difficulty])
        print("DEBUG: Content rules for distribution '%s': %s" % [distribution_id, content_rules])
        print("DEBUG: Chunk layout markers: %s" % str(chunk_definition.layout_markers))
    
    # Use strategy to distribute content
    var placements = _distribution_strategy.distribute_content(
        chunk_definition,
        flow_state,
        difficulty,
        content_rules,
        _placement_history
    )

    # DEBUG: Print all placements generated for this chunk
    print("ContentDistributionSystem: Placements generated for chunk '%s': %s" % [chunk_definition.chunk_id, placements])

    # Update placement history
    for placement in placements:
        _placement_history.append(placement)
    
    # Trim history if needed
    if _placement_history.size() > MAX_HISTORY_SIZE:
        _placement_history = _placement_history.slice(_placement_history.size() - MAX_HISTORY_SIZE)
    
    # Emit signals for each placement
    for placement in placements:
        # Emit the entire placement dictionary
        GlobalSignals.request_content_placement.emit(placement)
        
        # Emit analytics event with explicit coordinate fields
        var analytics_data = {
            "event_type": "content_placed",
            "category": placement["category"],
            "content_type": placement["type"],
            "distance_along_chunk": placement["distance_along_chunk"],
            "height": placement["height"],
            "width_offset": placement["width_offset"],
            "chunk_id": chunk_definition.chunk_id,
            "flow_state": FlowAndDifficultyController.FlowState.keys()[flow_state],
            "difficulty": difficulty
        }
        GlobalSignals.analytics_event.emit(analytics_data)
    
    if _debug_enabled:
        print("ContentDistributionSystem: Placed %d items for chunk '%s'" % [placements.size(), chunk_definition.chunk_id])

# Clear placement history (e.g., when starting a new stage)
func clear_placement_history() -> void:
    _placement_history.clear()
    if _debug_enabled:
        print("ContentDistributionSystem: Placement history cleared")

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
    _debug_enabled = enabled
    if _distribution_strategy:
        _distribution_strategy.set_debug_enabled(enabled)

# Load content distribution resource
func _load_content_distribution(distribution_id: String) -> ContentDistribution:
    # Try to load from path
    var resource_path = "res://resources/stage/content_distributions/%s_distribution.tres" % distribution_id
    
    if ResourceLoader.exists(resource_path):
        var resource = load(resource_path)
        if resource is ContentDistribution:
            if resource.validate():
                return resource
            else:
                push_warning("ContentDistributionSystem: Validation failed for '%s'" % resource_path)
        else:
            push_error("ContentDistributionSystem: Resource at '%s' is not a ContentDistribution" % resource_path)
    else:
        push_warning("ContentDistributionSystem: Resource not found at '%s'" % resource_path)
    
    # Try default path
    return ContentDistribution.get_default_resource()

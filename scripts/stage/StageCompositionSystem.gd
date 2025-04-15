class_name StageCompositionSystem
extends Node

# Import required classes
# In Godot 4.4+, classes with class_name are globally available

# Child components
@onready var stage_manager: StageCompositionManager = $StageCompositionManager
@onready var debug_overlay: StageDebugOverlay = $StageDebugOverlay if has_node("StageDebugOverlay") else null

# Debug flag
var _debug_enabled: bool = true

func _ready():
    # Connect to global signals
    GlobalSignals.stage_loaded.connect(_on_stage_loaded)
    GlobalSignals.stage_generation_failed.connect(_on_stage_generation_failed)
    GlobalSignals.flow_state_updated.connect(_on_flow_state_updated)
    
    if _debug_enabled:
        print("StageCompositionSystem: Ready")
        
        # Enable debug mode in child components
        if stage_manager:
            stage_manager.set_debug_enabled(true)
        
        if debug_overlay:
            debug_overlay.visible = true

# Initialize with motion profile resolver
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
    if stage_manager:
        stage_manager.initialize_with_resolver(resolver)
        
    if _debug_enabled:
        print("StageCompositionSystem: Initialized with MotionProfileResolver")

# Generate a stage with the given configuration
func generate_stage(config_id: String, game_mode: String = "story") -> void:
    if not stage_manager:
        push_error("StageCompositionSystem: StageCompositionManager not found")
        return
    
    if _debug_enabled:
        print("StageCompositionSystem: Generating stage '%s' in %s mode" % [config_id, game_mode])
    
    stage_manager.generate_stage(config_id, game_mode)

# Update player position
func update_player_position(position: Vector2) -> void:
    if not stage_manager:
        return
    
    stage_manager.update_player_position(position)
    
    # Update debug overlay if enabled
    if debug_overlay and debug_overlay.visible:
        debug_overlay.update_player_position(position)

# Record a performance event
func record_performance_event(metric: FlowAndDifficultyController.PerformanceMetric, value: float) -> void:
    if not stage_manager:
        return
    
    stage_manager.record_performance_event(metric, value)
    
    # Update debug overlay if enabled
    if debug_overlay and debug_overlay.visible:
        debug_overlay.update_performance_metric(metric, value)

# Set the player node for tracking
func set_player_node(player: Node) -> void:
    if not stage_manager:
        return
    
    stage_manager.set_player_node(player)
    
    # Set player in debug overlay if enabled
    if debug_overlay and player:
        debug_overlay.set_player_node(player)

# Enable/disable debug mode
func set_debug_enabled(enabled: bool) -> void:
    _debug_enabled = enabled
    
    if stage_manager:
        stage_manager.set_debug_enabled(enabled)
    
    if debug_overlay:
        debug_overlay.visible = enabled
        
    if _debug_enabled:
        print("StageCompositionSystem: Debug mode %s" % ("enabled" if enabled else "disabled"))

# Handle stage loaded event
func _on_stage_loaded(config) -> void:
    if _debug_enabled:
        print("StageCompositionSystem: Stage '%s' ready" % config.id)
    
    # Update debug overlay if enabled
    if debug_overlay and debug_overlay.visible:
        debug_overlay.update_stage_config(config)

# Handle stage generation failed event
func _on_stage_generation_failed(reason: String) -> void:
    push_error("StageCompositionSystem: Stage generation failed: %s" % reason)
    
    # Update debug overlay if enabled
    if debug_overlay and debug_overlay.visible:
        debug_overlay.show_error(reason)

# Handle flow state updated event
func _on_flow_state_updated(flow_state: FlowAndDifficultyController.FlowState) -> void:
    if _debug_enabled:
        print("StageCompositionSystem: Flow state updated to %s" % FlowAndDifficultyController.FlowState.keys()[flow_state])
    
    # Update debug overlay if enabled
    if debug_overlay and debug_overlay.visible:
        debug_overlay.update_flow_state(flow_state)

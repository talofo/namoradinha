class_name StageDebugOverlay
extends CanvasLayer

# Import required classes
# In Godot 4.4+, classes with class_name are globally available

# UI elements
@onready var flow_label: Label = $FlowStateLabel
@onready var difficulty_label: Label = $DifficultyLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var position_label: Label = $PositionLabel
@onready var config_info_label: Label = $ConfigInfoLabel
@onready var error_label: Label = $ErrorLabel
@onready var performance_metrics_label: Label = $PerformanceMetricsLabel

# References
var _player_node: Node = null
var _current_config: StageCompositionConfig = null
var _current_flow_state: FlowAndDifficultyController.FlowState = FlowAndDifficultyController.FlowState.LOW
var _performance_metrics: Dictionary = {}

func _ready():
    # Initialize UI
    flow_label.text = "Flow: LOW"
    difficulty_label.text = "Difficulty: low"
    progress_bar.value = 0
    position_label.text = "Position: (0, 0, 0)"
    config_info_label.text = "No stage loaded"
    error_label.text = ""
    error_label.visible = false
    performance_metrics_label.text = "Performance Metrics:"
    
    # Set control to be visible on top
    layer = 100

# Update the flow state display
func update_flow_state(flow_state: FlowAndDifficultyController.FlowState) -> void:
    _current_flow_state = flow_state
    flow_label.text = "Flow: %s" % FlowAndDifficultyController.FlowState.keys()[flow_state]
    
    # Update color based on flow state
    match flow_state:
        FlowAndDifficultyController.FlowState.LOW:
            flow_label.modulate = Color(0.5, 0.5, 1.0)  # Blue
        FlowAndDifficultyController.FlowState.RISING:
            flow_label.modulate = Color(0.5, 1.0, 0.5)  # Green
        FlowAndDifficultyController.FlowState.MID:
            flow_label.modulate = Color(1.0, 1.0, 0.5)  # Yellow
        FlowAndDifficultyController.FlowState.HIGH:
            flow_label.modulate = Color(1.0, 0.5, 0.5)  # Red
        FlowAndDifficultyController.FlowState.FALLING:
            flow_label.modulate = Color(1.0, 0.5, 1.0)  # Purple

# Update the stage config display
func update_stage_config(config: StageCompositionConfig) -> void:
    _current_config = config
    
    # Update difficulty label
    difficulty_label.text = "Difficulty: %s" % config.target_difficulty
    
    # Update config info
    var info_text = "Stage: %s\n" % config.id
    info_text += "Theme: %s\n" % config.theme
    info_text += "Flow Profile: %s\n" % str(config.flow_profile)
    info_text += "End Condition: %s\n" % _format_end_condition(config.story_end_condition)
    
    if not config.mandatory_events.is_empty():
        info_text += "Mandatory Events: %d\n" % config.mandatory_events.size()
    
    info_text += "Content Distribution: %s" % config.content_distribution_id
    
    config_info_label.text = info_text

# Update player position display
func update_player_position(position: Vector2) -> void:
    position_label.text = "Position: (%.1f, %.1f)" % [position.x, position.y]
    
    # Update progress bar if we have a config
    if _current_config:
        var effective_length = _current_config.get_effective_length()
        var progress = clamp(position.y / effective_length, 0.0, 1.0)
        progress_bar.value = progress * 100.0

# Update performance metric display
func update_performance_metric(metric: FlowAndDifficultyController.PerformanceMetric, value: float) -> void:
    _performance_metrics[metric] = value
    
    # Update performance metrics label
    var metrics_text = "Performance Metrics:\n"
    
    for m in _performance_metrics.keys():
        metrics_text += "%s: %.2f\n" % [FlowAndDifficultyController.PerformanceMetric.keys()[m], _performance_metrics[m]]
    
    performance_metrics_label.text = metrics_text

# Show an error message
func show_error(message: String) -> void:
    error_label.text = "ERROR: %s" % message
    error_label.visible = true
    
    # Hide error after 5 seconds
    await get_tree().create_timer(5.0).timeout
    error_label.visible = false

# Set the player node for tracking
func set_player_node(player: Node) -> void:
    _player_node = player

# Format the end condition for display
func _format_end_condition(end_condition: Dictionary) -> String:
    if end_condition.get("type") == "distance":
        return "Distance: %.1f" % end_condition.get("value", 0.0)
    elif end_condition.get("type") == "event":
        return "Event: %s (min dist: %.1f)" % [
            end_condition.get("event_name", ""),
            end_condition.get("trigger_distance", 0.0)
        ]
    else:
        return "Unknown"

# Draw chunk boundaries and other debug visuals
func _draw():
    # This would be implemented if we were using a custom drawing approach
    # For now, we're using Labels for simplicity
    pass

# Process function for real-time updates
func _process(_delta):
    # Update player position if we have a player node
    if _player_node and _player_node.has_method("get_global_position"):
        update_player_position(_player_node.get_global_position())

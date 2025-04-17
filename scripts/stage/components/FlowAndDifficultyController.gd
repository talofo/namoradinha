class_name FlowAndDifficultyController
extends RefCounted

# Flow state enum for clear state representation
enum FlowState {
    LOW,    # Low intensity, relaxed gameplay
    RISING, # Transitioning from low to mid intensity
    MID,    # Medium intensity, balanced gameplay
    HIGH,   # High intensity, challenging gameplay
    FALLING # Transitioning from high to mid/low intensity
}

# Performance metrics for dynamic flow adjustment
enum PerformanceMetric {
    PLAYER_SPEED,
    COLLECTIBLE_COLLECTION_RATE,
    OBSTACLE_COLLISION_RATE,
    BOOST_USAGE_RATE,
    COMBO_STREAK
}

# Configuration
var _flow_profile: Array = ["low", "mid", "low"] # Default profile if none provided
var _target_difficulty: String = "low" # Default difficulty if none provided
var _stage_length: float = 1000.0 # Default length if none provided

# Current state
var _current_distance: float = 0.0
var _current_flow_state: FlowState = FlowState.LOW
var _normalized_progress: float = 0.0 # 0.0 to 1.0 representing progress through stage

# Performance tracking
var _performance_metrics: Dictionary = {
    PerformanceMetric.PLAYER_SPEED: 0.0,
    PerformanceMetric.COLLECTIBLE_COLLECTION_RATE: 0.0,
    PerformanceMetric.OBSTACLE_COLLISION_RATE: 0.0,
    PerformanceMetric.BOOST_USAGE_RATE: 0.0,
    PerformanceMetric.COMBO_STREAK: 0
}

# Performance weights (how much each metric affects flow)
var _performance_weights: Dictionary = {
    PerformanceMetric.PLAYER_SPEED: 0.3,
    PerformanceMetric.COLLECTIBLE_COLLECTION_RATE: 0.2,
    PerformanceMetric.OBSTACLE_COLLISION_RATE: -0.3, # Negative because collisions reduce flow
    PerformanceMetric.BOOST_USAGE_RATE: 0.1,
    PerformanceMetric.COMBO_STREAK: 0.1
}

# Debug
var _debug_enabled: bool = false

# Initialize with stage configuration
func initialize(flow_profile: Array, target_difficulty: String, effective_stage_length: float) -> void:
    if flow_profile and flow_profile.size() > 0:
        _flow_profile = flow_profile
    
    if not target_difficulty.is_empty():
        _target_difficulty = target_difficulty
    
    if effective_stage_length > 0:
        _stage_length = effective_stage_length
    
    # Reset state
    _current_distance = 0.0
    _normalized_progress = 0.0
    _current_flow_state = _string_to_flow_state(_flow_profile[0])
    
    if _debug_enabled:
        print("FlowAndDifficultyController: Initialized with profile %s, difficulty %s, length %f" % 
              [str(_flow_profile), _target_difficulty, _stage_length])

# Update based on player position
func update_position(distance: float) -> void:
    _current_distance = distance
    _normalized_progress = clamp(distance / _stage_length, 0.0, 1.0)
    
    var new_flow_state = _calculate_flow_state()
    if new_flow_state != _current_flow_state:
        _current_flow_state = new_flow_state
        if _debug_enabled:
            print("FlowAndDifficultyController: Flow state changed to %s at distance %f (progress: %f)" % 
                  [FlowState.keys()[_current_flow_state], distance, _normalized_progress])

# Record a performance event that might affect flow
func record_performance_event(metric: PerformanceMetric, value: float) -> void:
    if metric in _performance_metrics:
        _performance_metrics[metric] = value
        if _debug_enabled:
            print("FlowAndDifficultyController: Recorded %s = %f" % [PerformanceMetric.keys()[metric], value])

# Get the current flow state
func get_current_flow_state() -> FlowState:
    return _current_flow_state

# Get the current flow state as a string
func get_current_flow_state_string() -> String:
    return FlowState.keys()[_current_flow_state]

# Get the current difficulty
func get_current_difficulty() -> String:
    return _target_difficulty

# Get the normalized progress (0.0 to 1.0)
func get_normalized_progress() -> float:
    return _normalized_progress

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
    _debug_enabled = enabled

# Calculate the current flow state based on position and performance
func _calculate_flow_state() -> FlowState:
    # Base calculation on normalized progress through the flow profile
    var profile_index = int(_normalized_progress * (_flow_profile.size() - 1))
    profile_index = clamp(profile_index, 0, _flow_profile.size() - 1)
    
    var base_flow_state = _string_to_flow_state(_flow_profile[profile_index])
    
    # Apply performance modifiers if we have meaningful data
    var _performance_modifier = _calculate_performance_modifier()
    
    # For now, we'll just use the base flow state from the profile
    # In a more advanced implementation, we could adjust up/down based on performance
    # e.g., if performance_modifier > threshold, increase flow state
    
    return base_flow_state

# Calculate a modifier based on performance metrics
func _calculate_performance_modifier() -> float:
    var modifier = 0.0
    
    for metric in _performance_metrics.keys():
        if _performance_weights.has(metric):
            modifier += _performance_metrics[metric] * _performance_weights[metric]
    
    return modifier

# Convert string flow state to enum
func _string_to_flow_state(state_string: String) -> FlowState:
    match state_string.to_upper():
        "LOW": return FlowState.LOW
        "RISING": return FlowState.RISING
        "MID": return FlowState.MID
        "HIGH": return FlowState.HIGH
        "FALLING": return FlowState.FALLING
        _: return FlowState.LOW # Default to LOW if unknown

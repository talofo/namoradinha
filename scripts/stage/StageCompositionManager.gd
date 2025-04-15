class_name StageCompositionManager
extends Node

# Import required classes
# In Godot 4.4+, classes with class_name are globally available

# Game mode constants
const GAME_MODE_STORY = "story"
const GAME_MODE_ARCADE = "arcade"

# Child components
@onready var chunk_management_system: ChunkManagementSystem = $ChunkManagementSystem
@onready var content_distribution_system: ContentDistributionSystem = $ContentDistributionSystem
@onready var stage_config_system: StageConfigSystem = $StageConfigSystem

# State tracking
var _current_game_mode: String = GAME_MODE_STORY
var _current_stage_config: StageCompositionConfig = null
var _current_end_condition: Dictionary = {}
var _listening_for_event: String = ""
var _flow_controller: FlowAndDifficultyController = null
var _player_node: Node = null
var _motion_profile_resolver: MotionProfileResolver = null

# Debug flag
var _debug_enabled: bool = false

func _ready():
	# Connect to global signals
	GlobalSignals.stage_generation_requested.connect(_on_stage_generation_requested)
	GlobalSignals.gameplay_event_triggered.connect(_on_gameplay_event_triggered)
	GlobalSignals.biome_changed.connect(_on_biome_change_detected)
	
	# Create flow controller
	_flow_controller = FlowAndDifficultyController.new()
	
	if _debug_enabled:
		print("StageCompositionManager: Ready")

# Initialize with motion profile resolver
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
	_motion_profile_resolver = resolver
	if _debug_enabled:
		print("StageCompositionManager: Initialized with MotionProfileResolver")

# Generate a stage with the given configuration
func generate_stage(config_id: String, game_mode: String = GAME_MODE_STORY) -> void:
	# Load the stage config
	var config = stage_config_system.get_config(config_id)
	if not config:
		push_error("StageCompositionManager: Failed to load config '%s'" % config_id)
		GlobalSignals.stage_generation_failed.emit("Failed to load config '%s'" % config_id)
		return
	
	# Emit the stage generation requested signal
	GlobalSignals.stage_generation_requested.emit(config, game_mode)

# Handle stage generation request
func _on_stage_generation_requested(config: StageCompositionConfig, game_mode: String) -> void:
	if _debug_enabled:
		print("StageCompositionManager: Generating stage '%s' in %s mode" % [config.id, game_mode])
	
	# Store current state
	_current_game_mode = game_mode
	_current_stage_config = config
	
	# Store end condition for later checking
	_current_end_condition = config.story_end_condition.duplicate()
	_listening_for_event = ""
	
	if _current_end_condition.get("type") == "event":
		_listening_for_event = _current_end_condition.get("event_name", "")
	
	# Calculate effective length
	var effective_length = config.get_effective_length()
	
	# Initialize flow controller
	_flow_controller.initialize(
		config.flow_profile,
		config.target_difficulty,
		effective_length
	)
	
	# Set debug mode if needed
	if _debug_enabled:
		_flow_controller.set_debug_enabled(true)
		chunk_management_system.set_debug_enabled(true)
		content_distribution_system.set_debug_enabled(true)
	
	# Initialize subsystems
	content_distribution_system.initialize(_flow_controller)
	# Pass content distribution system to chunk management
	chunk_management_system.initialize(config, _flow_controller, content_distribution_system)
	
	# Clear any previous content
	content_distribution_system.clear_placement_history()
	
	# Generate initial chunks
	chunk_management_system.generate_initial_chunks(3)
	
	# Emit analytics event
	GlobalSignals.analytics_event.emit({
		"event_type": "stage_generated",
		"stage_id": config.id,
		"game_mode": game_mode,
		"theme": config.theme,
		"difficulty": config.target_difficulty,
		"effective_length": effective_length
	})
	
	# Emit stage loaded signal
	GlobalSignals.stage_loaded.emit(config)
	
	if _debug_enabled:
		print("StageCompositionManager: Stage '%s' generated successfully" % config.id)

# Update player position
func update_player_position(position: Vector2) -> void:
	if not _current_stage_config or not _flow_controller:
		return
	
	# Update flow controller
	_flow_controller.update_position(position.y)
	
	# Update chunk management system
	chunk_management_system.update_player_position(position)
	
	# Check for story mode end condition (distance type)
	if _current_game_mode == GAME_MODE_STORY and _current_end_condition.get("type") == "distance":
		var end_distance = _current_end_condition.get("value", 0.0)
		if position.y >= end_distance:
			_trigger_story_stage_complete()
	
	# Check for arcade mode transition
	if _current_game_mode == GAME_MODE_ARCADE:
		var progress = _flow_controller.get_normalized_progress()
		if progress >= 0.95:  # Near the end of the stage
			_handle_arcade_transition()

# Record a performance event
func record_performance_event(metric: FlowAndDifficultyController.PerformanceMetric, value: float) -> void:
	if _flow_controller:
		_flow_controller.record_performance_event(metric, value)
		
		# Emit analytics event
		GlobalSignals.analytics_event.emit({
			"event_type": "performance_recorded",
			"metric": FlowAndDifficultyController.PerformanceMetric.keys()[metric],
			"value": value,
			"flow_state": FlowAndDifficultyController.FlowState.keys()[_flow_controller.get_current_flow_state()],
			"progress": _flow_controller.get_normalized_progress()
		})

# Handle gameplay events
func _on_gameplay_event_triggered(event_name: String, event_data: Dictionary) -> void:
	if _current_game_mode == GAME_MODE_STORY and event_name == _listening_for_event:
		# Check if we've reached the minimum distance for the event to trigger the end
		var trigger_distance = _current_end_condition.get("trigger_distance", 0.0)
		var current_distance = event_data.get("distance", 0.0)
		
		if current_distance >= trigger_distance:
			_trigger_story_stage_complete()
	
	# Emit analytics event
	GlobalSignals.analytics_event.emit({
		"event_type": "gameplay_event_processed",
		"event_name": event_name,
		"event_data": event_data,
		"current_game_mode": _current_game_mode,
		"listening_for_event": _listening_for_event
	})

# Handle biome changes
func _on_biome_change_detected(old_biome: String, new_biome: String) -> void:
	if _debug_enabled:
		print("StageCompositionManager: Biome changed from '%s' to '%s'" % [old_biome, new_biome])
	
	# Update MotionProfileResolver with the new biome's ground config if available
	if _motion_profile_resolver:
		var biome_config_path = "res://resources/motion/profiles/ground/%s_ground.tres" % new_biome
		if ResourceLoader.exists(biome_config_path):
			var biome_config = load(biome_config_path)
			if biome_config:
				_motion_profile_resolver.set_ground_config(biome_config)
				if _debug_enabled:
					print("StageCompositionManager: Updated ground config for biome '%s'" % new_biome)

# Trigger story stage completion
func _trigger_story_stage_complete() -> void:
	if not _current_stage_config:
		return
	
	if _debug_enabled:
		print("StageCompositionManager: Story stage '%s' completed" % _current_stage_config.id)
	
	# Emit story stage completed signal
	GlobalSignals.story_stage_completed.emit(_current_stage_config.id)
	
	# Emit analytics event
	GlobalSignals.analytics_event.emit({
		"event_type": "story_stage_completed",
		"stage_id": _current_stage_config.id,
		"completion_type": _current_end_condition.get("type", "unknown"),
		"progress": _flow_controller.get_normalized_progress() if _flow_controller else 0.0
	})
	
	# Reset state
	_current_stage_config = null
	_current_end_condition.clear()
	_listening_for_event = ""

# Handle arcade mode transition
func _handle_arcade_transition() -> void:
	if not _current_stage_config or not _current_stage_config.next_stage_logic:
		return
	
	var next_logic = _current_stage_config.next_stage_logic
	var next_config_id = ""
	
	# Determine next stage based on logic
	if next_logic.has("mode") and next_logic.has("theme"):
		if next_logic.mode == "random_theme":
			# Get a random config with the specified theme
			next_config_id = stage_config_system.get_config_by_theme(next_logic.theme).id
		elif next_logic.mode == "specific":
			# Use a specific config ID
			next_config_id = next_logic.get("config_id", "")
	
	if next_config_id.is_empty():
		if _debug_enabled:
			print("StageCompositionManager: No valid next stage found for arcade transition")
		return
	
	if _debug_enabled:
		print("StageCompositionManager: Transitioning to next arcade stage '%s'" % next_config_id)
	
	# Load the next config
	var next_config = stage_config_system.get_config(next_config_id)
	if not next_config:
		push_error("StageCompositionManager: Failed to load next config '%s'" % next_config_id)
		return
	
	# Emit analytics event
	GlobalSignals.analytics_event.emit({
		"event_type": "arcade_transition",
		"from_stage": _current_stage_config.id,
		"to_stage": next_config_id,
		"transition_logic": next_logic
	})
	
	# Generate the next stage
	generate_stage(next_config_id, GAME_MODE_ARCADE)

# Set the player node for tracking
func set_player_node(player: Node) -> void:
	_player_node = player
	if _debug_enabled:
		print("StageCompositionManager: Player node set")

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
	_debug_enabled = enabled
	
	if _flow_controller:
		_flow_controller.set_debug_enabled(enabled)
	
	if chunk_management_system:
		chunk_management_system.set_debug_enabled(enabled)
	
	if content_distribution_system:
		content_distribution_system.set_debug_enabled(enabled)
	
	if stage_config_system:
		stage_config_system.set_debug_enabled(enabled)

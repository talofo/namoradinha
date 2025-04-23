class_name VisualBackgroundSystem
extends Node2D

signal theme_changed(theme_name)
signal transition_completed

# References to other systems
var environment_system
var camera_system
var theme_database

# References to managed nodes
@onready var parallax_controller = $ParallaxLayerController

# Configuration
@export var use_camera_signal: bool = true  # If false, poll in _process instead
@export var performance_monitoring: bool = true

# State
var current_theme_name: String = ""
var initial_camera_position: Vector2 = Vector2.ZERO

func _ready():
	# Setup references to dependencies (adjust based on your project structure)
	environment_system = get_node_or_null("/root/Game/EnvironmentSystem")
	if not environment_system:
		environment_system = get_node_or_null("../")  # Try to get parent if we're a child of EnvironmentSystem
	
	camera_system = get_node_or_null("/root/Game/CameraSystem")
	
	# Get initial camera position if available
	if camera_system:
		initial_camera_position = camera_system.get_camera_position()
	
	# Get theme database from environment system if possible
	if environment_system and environment_system.has_method("get_theme_database"):
		theme_database = environment_system.get_theme_database()
	else:
		theme_database = get_node_or_null("/root/Game/ThemeDatabase")
	
	# Connect signals
	if environment_system:
		if environment_system.has_signal("visuals_updated"):
			environment_system.visuals_updated.connect(_on_environment_visuals_updated)
	
	if camera_system and use_camera_signal:
		if camera_system.has_signal("camera_moved"):
			camera_system.camera_moved.connect(_on_camera_moved)
		else:
			push_warning("VisualBackgroundSystem: CameraSystem does not have camera_moved signal")

func _process(_delta):
	# Optional: Poll camera position if not using signals
	if camera_system and not use_camera_signal:
		_update_camera_position(camera_system.get_camera_position())

# Called when the environment system updates visuals
func _on_environment_visuals_updated(theme_id: String, _biome_id: String):
	if environment_system and theme_database:
		var theme_config = theme_database.get_visual_background_theme(theme_id)
		if theme_config:
			apply_theme(theme_config)
		else:
			push_warning("VisualBackgroundSystem: No visual background theme found for theme_id: " + theme_id)

func apply_theme(theme_config: Resource):
	if not theme_config:
		push_error("Invalid theme_config passed to VisualBackgroundSystem")
		return
	
	# Save current theme name
	current_theme_name = theme_config.theme_name
	
	# Check performance guideline (not a hard limit)
	if performance_monitoring and theme_config.layers.size() > 7:
		push_warning("Performance Warning: Theme '%s' has %d layers, which exceeds the recommended 7 layers. This may impact performance." 
			% [theme_config.theme_name, theme_config.layers.size()])
	
	# Clear existing layers
	parallax_controller.clear_layers()
	
	# Build new layers from theme config with initial camera position
	parallax_controller.build_layers(theme_config.layers, initial_camera_position)
	
	# Emit signals for other systems
	theme_changed.emit(current_theme_name)
	
	# Visual background transitions are immediate, so emit transition_completed right away
	transition_completed.emit()

func _on_camera_moved(camera_position: Vector2, _camera_zoom: Vector2):
	_update_camera_position(camera_position)

func _update_camera_position(camera_pos: Vector2):
	# Update parallax controller with new camera position
	parallax_controller.update_scroll(camera_pos)

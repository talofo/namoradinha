class_name SharedGroundManager
extends Node

# Signal to notify when ground is created
signal ground_created(ground_data: Array)

# Configuration
var ground_width: float = 900000.0
var ground_height: float = 230.0
var ground_y_position: float = 850.0

# State tracking
var _ground_created: bool = false
var _ground_node: StaticBody2D = null

# Debug mode
var debug_enabled: bool = false

# Reference to environment system for visual updates
var _environment_system: EnvironmentSystem = null

func _init(environment_system: EnvironmentSystem = null):
	_environment_system = environment_system

# Create a single shared ground for the entire level
func create_shared_ground(parent_node: Node) -> StaticBody2D:
	if _ground_created and _ground_node and is_instance_valid(_ground_node):
		if debug_enabled:
			print("SharedGroundManager: Ground already exists, returning existing ground")
		return _ground_node
	
	# Create ground with collision shape
	var ground = StaticBody2D.new()
	ground.name = "SharedGround"
	ground.position = Vector2(0, ground_y_position)
	ground.collision_layer = 1  # Set to appropriate layer for ground
	ground.collision_mask = 0   # Ground doesn't need to detect collisions
	parent_node.add_child(ground)
	
	# Create collision shape for ground
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	ground.add_child(collision_shape)
	
	# Create rectangle shape with size based on chunk length
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ground_width, ground_height)
	collision_shape.shape = shape
	
	# Create visual representation for the ground (semi-transparent for debugging)
	var visual = ColorRect.new()
	visual.size = Vector2(ground_width, ground_height)
	visual.position = Vector2(-ground_width/2, -ground_height/2)  # Center the rect
	visual.color = Color(0.5, 0.5, 0.5, 0.3)  # Semi-transparent gray
	ground.add_child(visual)
	
	# Collect ground data for visuals
	var ground_data = []
	var data = {
		"position": Vector2(0, 0),  # Relative to ground
		"size": Vector2(ground_width, ground_height)  # Size of the ground
	}
	ground_data.append(data)
	
	# Emit signal for GroundVisualManager to create visuals
	if _environment_system and _environment_system.ground_manager:
		_environment_system.ground_manager.apply_ground_visuals(ground_data)
	
	# Emit signal for other systems that might need to know about ground creation
	ground_created.emit(ground_data)
	
	_ground_created = true
	_ground_node = ground
	
	if debug_enabled:
		print("SharedGroundManager: Created shared ground for the entire level")
	
	return ground

# Set the ground dimensions
func set_ground_dimensions(width: float, height: float, y_position: float) -> void:
	ground_width = width
	ground_height = height
	ground_y_position = y_position
	
	if debug_enabled:
		print("SharedGroundManager: Ground dimensions set to width=%f, height=%f, y_position=%f" % 
			[width, height, y_position])

# Check if ground exists
func has_ground() -> bool:
	return _ground_created and _ground_node != null and is_instance_valid(_ground_node)

# Get the ground node if it exists
func get_ground_node() -> StaticBody2D:
	if has_ground():
		return _ground_node
	return null

# Set debug mode
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled

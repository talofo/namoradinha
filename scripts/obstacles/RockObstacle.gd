# scripts/obstacles/RockObstacle.gd
# Implementation of a rock obstacle that combines Weakener and Deflector types.
class_name RockObstacle
extends Node2D

# Configuration resources for the obstacle types
@export var weakener_config: WeakenerConfig
@export var deflector_config: DeflectorConfig

# Optional collision radius for near miss detection
@export var near_miss_radius: float = 100.0

# Returns the types of obstacles this node represents
func get_obstacle_types() -> Array:
	return ["weakener", "deflector"]

# Returns the configuration for all obstacle types
func get_obstacle_config() -> Dictionary:
	var config = {}
	
	# Add weakener config
	if weakener_config:
		config["weakener"] = {
			"velocity_multiplier": weakener_config.velocity_multiplier,
			"apply_to_x": weakener_config.apply_to_x,
			"apply_to_y": weakener_config.apply_to_y
		}
	else:
		# Default values if no config is set
		config["weakener"] = {
			"velocity_multiplier": 0.6,
			"apply_to_x": true,
			"apply_to_y": true
		}
	
	# Add deflector config
	if deflector_config:
		config["deflector"] = {
			"deflect_angle": deflector_config.deflect_angle,
			"angle_variance": deflector_config.angle_variance,
			"trigger_direction": deflector_config.trigger_direction
		}
	else:
		# Default values if no config is set
		config["deflector"] = {
			"deflect_angle": 15.0,
			"angle_variance": 5.0,
			"trigger_direction": "top"
		}
	
	return config

# Returns the radius for near miss detection
func get_near_miss_radius() -> float:
	return near_miss_radius

# Returns the collision radius for collision detection
func get_collision_radius() -> float:
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CircleShape2D:
			return collision_shape.shape.radius
		elif collision_shape.shape is RectangleShape2D:
			# Use the average of width and height for rectangle
			return (collision_shape.shape.size.x + collision_shape.shape.size.y) / 4.0
	
	# Default value if no shape is found
	return 32.0

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Ensure this node is in the "obstacles" group
	if not is_in_group("obstacles"):
		add_to_group("obstacles")

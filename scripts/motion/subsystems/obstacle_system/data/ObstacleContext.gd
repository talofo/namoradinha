# scripts/motion/subsystems/obstacle_system/data/ObstacleContext.gd
# Input data structure for obstacle calculations.
class_name ObstacleContext
extends RefCounted

var entity_id: int = 0
var entity_velocity: Vector2 = Vector2.ZERO
var entity_position: Vector2 = Vector2.ZERO
var collision_normal: Vector2 = Vector2.ZERO
var is_airborne: bool = false
var is_sliding: bool = false
var obstacle_node: Node2D = null
var physics_config = null # Reference to the loaded PhysicsConfig resource

# Optional extensibility mechanism for future obstacle types
var _properties: Dictionary = {}

# Static constructor from collision data
static func new_from_collision(collision_data: Dictionary) -> ObstacleContext:
	var context = ObstacleContext.new()
	context.entity_id = collision_data.get("entity_id", 0)
	context.entity_velocity = collision_data.get("velocity", Vector2.ZERO)
	context.entity_position = collision_data.get("position", Vector2.ZERO)
	context.collision_normal = collision_data.get("normal", Vector2.UP)
	context.is_airborne = collision_data.get("is_airborne", false)
	context.is_sliding = collision_data.get("is_sliding", false)
	context.obstacle_node = collision_data.get("collider", null)
	context.physics_config = collision_data.get("physics_config", null)
	return context

# Set a custom property
func set_property(name: String, value) -> void:
	_properties[name] = value
	
# Get a custom property with optional default value
func get_property(name: String, default = null):
	return _properties.get(name, default)

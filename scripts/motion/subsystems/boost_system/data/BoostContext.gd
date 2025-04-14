# scripts/motion/subsystems/boost_system/data/BoostContext.gd
# Input data structure for boost calculations.
class_name BoostContext
extends RefCounted

var entity_id: int = 0
var is_airborne: bool = false
var is_rising: bool = false # True if vertical velocity is significantly positive (moving up)
var current_velocity: Vector2 = Vector2.ZERO
var position: Vector2 = Vector2.ZERO
var requested_direction: Vector2 = Vector2.ZERO # Optional direction hint from the trigger
var physics_config = null # Reference to the loaded PhysicsConfig resource
var player_node = null # Reference to the player node
var motion_profile = {} # Motion profile data

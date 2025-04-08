class_name CollisionContext
extends RefCounted

# Preload dependent data structures
const IncomingMotionState = preload("res://scripts/motion/subsystems/bounce_system/data/IncomingMotionState.gd")
const ImpactSurfaceDataClass = preload("res://scripts/motion/subsystems/bounce_system/data/ImpactSurfaceData.gd")
const PlayerBounceProfileClass = preload("res://scripts/motion/subsystems/bounce_system/data/PlayerBounceProfile.gd")

## Aggregates all necessary information for a bounce calculation.
## Passed as input to the BounceSystem's calculation method.

# Player's motion state just before impact.
var incoming_motion_state: IncomingMotionState = null

# Data about the surface collided with.
var impact_surface_data: ImpactSurfaceData = null

# Player's permanent bounce modifiers (traits, equipment).
var player_bounce_profile: PlayerBounceProfile = null

# Current gravity vector affecting the player.
var current_gravity: Vector2 = Vector2.DOWN * ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

# Flag to indicate if debug data should be generated (e.g., for editor/debug builds).
var generate_debug_data: bool = false

func _init(
	p_incoming_motion_state: IncomingMotionState = null,
	p_impact_surface_data: ImpactSurfaceData = null,
	p_player_bounce_profile: PlayerBounceProfile = null,
	p_current_gravity: Vector2 = Vector2.DOWN * ProjectSettings.get_setting("physics/2d/default_gravity", 980.0),
	p_generate_debug_data: bool = false
) -> void:
	incoming_motion_state = p_incoming_motion_state if p_incoming_motion_state != null else IncomingMotionState.new()
	impact_surface_data = p_impact_surface_data if p_impact_surface_data != null else ImpactSurfaceDataClass.new()
	player_bounce_profile = p_player_bounce_profile if p_player_bounce_profile != null else PlayerBounceProfileClass.new()
	current_gravity = p_current_gravity
	generate_debug_data = p_generate_debug_data

# Removed static func new_from_raw(raw_data: Dictionary) -> CollisionContext:
# The caller (test script or MotionSystemCore) is responsible for constructing 
# the CollisionContext object correctly using its _init constructor.

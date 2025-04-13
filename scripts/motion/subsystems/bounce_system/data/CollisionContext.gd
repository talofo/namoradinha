class_name CollisionContext
extends RefCounted

# All these classes are available globally via class_name

## Aggregates all necessary information for a bounce calculation.
## Passed as input to the BounceSystem's calculation method.

# Reference to the player node itself (needed for profile resolution).
var player_node: Node = null

# Player's motion state just before impact.
var incoming_motion_state: IncomingMotionState = null

# Data about the surface collided with.
var impact_surface_data: CollisionSurfaceData = null

# Player's permanent bounce modifiers (traits, equipment).
var player_bounce_profile: PlayerBounceProfile = null

# Current gravity vector affecting the player.
var current_gravity: Vector2 = Vector2.DOWN * ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

# Flag to indicate if debug data should be generated (e.g., for editor/debug builds).
var generate_debug_data: bool = false

func _init(
	p_player_node: Node, # Added player_node parameter
	p_incoming_motion_state: IncomingMotionState = null,
	p_impact_surface_data: CollisionSurfaceData = null,
	p_player_bounce_profile: PlayerBounceProfile = null,
	p_current_gravity: Vector2 = Vector2.DOWN * ProjectSettings.get_setting("physics/2d/default_gravity", 980.0),
	p_generate_debug_data: bool = false
) -> void:
	# Ensure player_node is valid
	if not is_instance_valid(p_player_node):
		push_error("CollisionContext: Invalid player_node provided during initialization.")
		# Optionally handle this error more gracefully depending on requirements
		
	player_node = p_player_node
	incoming_motion_state = p_incoming_motion_state if p_incoming_motion_state != null else IncomingMotionState.new()
	impact_surface_data = p_impact_surface_data if p_impact_surface_data != null else CollisionSurfaceData.new()
	player_bounce_profile = p_player_bounce_profile if p_player_bounce_profile != null else PlayerBounceProfile.new()
	current_gravity = p_current_gravity
	generate_debug_data = p_generate_debug_data

# Removed static func new_from_raw(raw_data: Dictionary) -> CollisionContext:
# The caller (test script or MotionSystemCore) is responsible for constructing 
# the CollisionContext object correctly using its _init constructor.

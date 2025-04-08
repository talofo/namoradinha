class_name PlayerCharacter
extends CharacterBody2D

# === REFERENCES ===
var motion_system = null

# === STATE VARIABLES ===
var has_launched: bool = false
var is_sliding: bool = false

# === TRACKING VARIABLES ===
var entity_id: int = 0
var floor_position_y: float = 0.0
var max_height_y: float = 0.0

# Add setter method for motion system
func set_motion_system(system) -> void:
	motion_system = system
	# Store entity ID if motion system is available
	if motion_system:
		entity_id = get_instance_id()

func _ready():
	# If motion_system is null here, it should be set by the parent/spawner
	if not motion_system:
		pass # No motion system provided

# Main physics process
func _physics_process(delta: float) -> void:
	# Skip if not in motion
	if not has_launched and not is_sliding:
		return

	# Create motion context for this frame
	var motion_context = {
		# Entity information
		"entity_id": entity_id,
		"entity_type": "player",

		# Position and physics
		"position": position,
		"velocity": velocity,
		"delta": delta,
		# Gravity is now handled internally by MotionSystem based on PhysicsConfig

		# State
		"is_on_floor": is_on_floor(),
		"has_launched": has_launched,
		"is_sliding": is_sliding,

		# Tracking
		"max_height_y": max_height_y,
		"floor_position_y": floor_position_y,

		# Material
		"material": _detect_floor_material()
	}

	# Apply motion physics via MotionSystem
	if motion_system and motion_system.has_method("resolve_frame_motion"):
		var motion_result = motion_system.resolve_frame_motion(motion_context)

		# Apply results from motion system
		if motion_result.has("velocity"):
			velocity = motion_result.velocity
		if motion_result.has("has_launched"):
			has_launched = motion_result.has_launched
		if motion_result.has("is_sliding"):
			is_sliding = motion_result.is_sliding

	# Handle floor collision
	if is_on_floor():
		floor_position_y = position.y
		_handle_floor_collision()

	# Perform the actual movement
	move_and_slide()

	# Removed problematic velocity preservation logic that was overriding physics results.

	# Round position to integer pixels to prevent subpixel flickering
	position = position.round() # Re-enabled for testing abrupt stop issue

# Handle floor collision with MotionSystem integration
func _handle_floor_collision() -> void:
	print("[PlayerCharacter._handle_floor_collision] Velocity BEFORE creating collision_info: ", velocity) # DEBUG PRINT
	# Create collision info with all necessary context
	var collision_info = {
		"entity_id": entity_id,
		"position": position,
		"normal": get_floor_normal(),
		"velocity": velocity,
		"has_launched": has_launched,
		"is_sliding": is_sliding,
		"max_height_y": max_height_y,
		"floor_position_y": floor_position_y,
		"material": _detect_floor_material()
	}

	# Let MotionSystem handle collision response
	if motion_system and motion_system.has_method("resolve_collision"):
		print("[PlayerCharacter._handle_floor_collision] Calling motion_system.resolve_collision with info: ", collision_info) # DEBUG PRINT
		var collision_result = motion_system.resolve_collision(collision_info)
		print("[PlayerCharacter._handle_floor_collision] Collision result received: ", collision_result) # DEBUG PRINT

		# Apply the collision result
		if collision_result.has("velocity"):
			print("[PlayerCharacter._handle_floor_collision] Applying velocity from result: ", collision_result.velocity) # DEBUG PRINT
			velocity = collision_result.velocity
		if collision_result.has("has_launched"):
			has_launched = collision_result.has_launched
		if collision_result.has("is_sliding"):
			is_sliding = collision_result.is_sliding
		if collision_result.has("max_height_y"):
			max_height_y = collision_result.max_height_y


# Get the current bounce count from the BounceSystem
func get_bounce_count() -> int:
	if motion_system and motion_system.has_method("get_subsystem"):
		var bounce_system = motion_system.get_subsystem("BounceSystem")
		if bounce_system and bounce_system.has_method("get_bounce_count"):
			return bounce_system.get_bounce_count(entity_id)
	return -1

# Detect the material of the floor at the current position
# TODO: Implement logic to detect material based on the actual floor collider.
#       This will likely involve getting the collider via get_floor_collider(),
#       finding an attached script (e.g., GroundMaterialInfo.gd) on it or its owner,
#       and reading a 'material_name' property from that script.
#       The returned name should correspond to a key in PhysicsConfig.material_properties.
# For now, always return "default" to ensure consistent floor physics.
func _detect_floor_material() -> String:
	return "default"

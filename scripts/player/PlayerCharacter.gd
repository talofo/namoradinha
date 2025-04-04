class_name PlayerCharacter
extends CharacterBody2D

# === REFERENCES ===
var motion_system = null
var bounce_system = null

# === STATE VARIABLES ===
var has_launched: bool = false
var is_sliding: bool = false

# === TRACKING VARIABLES ===
var entity_id: int = 0
var floor_position_y: float = 0.0
var max_height_y: float = 0.0

func _ready():
	# Get references to the motion system and subsystems
	motion_system = get_node_or_null("/root/Game/MotionSystem")
	if motion_system:
		bounce_system = motion_system.get_subsystem("BounceSystem")
		
		# Register with bounce system
		entity_id = get_instance_id()
		if bounce_system and bounce_system.has_method("register_entity"):
			bounce_system.register_entity(entity_id, position)
	else:
		push_error("[PlayerCharacter] MotionSystem not found!")

func _exit_tree():
	# Clean up registrations
	if bounce_system and bounce_system.has_method("unregister_entity"):
		bounce_system.unregister_entity(entity_id)

# Launch the player with a given direction vector
func launch(direction: Vector2) -> void:
	print("PlayerCharacter: Launching with direction ", direction)
	
	# Set velocity directly - this is critical for determining jump height
	velocity = direction
	has_launched = true
	is_sliding = false
	
	# Record positions for height tracking
	floor_position_y = position.y
	max_height_y = position.y
	
	# Record launch in bounce system
	if bounce_system and bounce_system.has_method("record_launch"):
		bounce_system.record_launch(entity_id, direction, position)

# Main physics process
func _physics_process(delta: float) -> void:
	# Skip if not in motion
	if not has_launched and not is_sliding:
		return

	# Track height for bounce system
	if bounce_system and has_launched:
		bounce_system.update_max_height(entity_id, position)

	# Create motion context for this frame
	var motion_context = {
		"entity_id": entity_id,
		"position": position,
		"velocity": velocity,
		"delta": delta,
		"gravity": motion_system.physics_config.gravity,
		"is_on_floor": is_on_floor(),
		"has_launched": has_launched,
		"is_sliding": is_sliding
	}

	# Apply motion physics (gravity, etc.)
	if motion_system.has_method("resolve_frame_motion"):
		var motion_result = motion_system.resolve_frame_motion(motion_context)
		if motion_result.has("velocity"):
			velocity = motion_result.velocity

	# Handle floor collision
	if is_on_floor():
		floor_position_y = position.y
		_handle_floor_collision()

	# Perform the actual movement
	var original_velocity = velocity
	move_and_slide()
	
	# If we're in air, preserve velocity to prevent Godot's built-in physics from interfering
	if has_launched and !is_on_floor():
		velocity = original_velocity

# Handle floor collision with MotionSystem integration
func _handle_floor_collision() -> void:
	# Create collision info
	var collision_info = {
		"entity_id": entity_id,
		"position": position,
		"normal": get_floor_normal(),
		"velocity": velocity,
		"has_launched": has_launched,
		"is_sliding": is_sliding,
		"max_height_y": max_height_y,
		"floor_position_y": floor_position_y
	}

	# Let MotionSystem handle collision response
	var collision_result = motion_system.resolve_collision(collision_info)
	
	# Apply the collision result
	if collision_result.has("velocity"):
		velocity = collision_result.velocity
	if collision_result.has("has_launched"):
		has_launched = collision_result.has_launched
	if collision_result.has("is_sliding"):
		is_sliding = collision_result.is_sliding
	if collision_result.has("max_height_y"):
		max_height_y = collision_result.max_height_y

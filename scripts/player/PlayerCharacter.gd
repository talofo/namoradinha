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

func _ready():
	# Get reference to the motion system
	motion_system = get_node_or_null("/root/Game/MotionSystem")
	if motion_system:
		# Store entity ID
		entity_id = get_instance_id()
	else:
		push_error("[PlayerCharacter] MotionSystem not found!")

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
	position = position.round()

# Handle floor collision with MotionSystem integration
func _handle_floor_collision() -> void:
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

# Detect the material of the floor at the current position
func _detect_floor_material() -> String:
	# Default material
	var floor_material = "default"
	
	# Simple position-based detection
	if position.x < -1000:
		floor_material = "ice"
	elif position.x > 1000:
		floor_material = "mud"
	elif position.x > -200 and position.x < 200:
		floor_material = "rubber"
	
	return floor_material

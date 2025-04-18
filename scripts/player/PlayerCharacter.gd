class_name PlayerCharacter
extends CharacterBody2D

# === REFERENCES ===
var motion_system = null

# === CONFIGURATION ===
## Duration of cooldown between boosts (in seconds)
@export var boost_cooldown_duration: float = 0.5

## Duration to ignore collisions after a bounce (in seconds)
@export var collision_grace_duration: float = 0.1

## Duration to skip gravity after a bounce (in seconds)
@export var post_bounce_duration: float = 0.1

## Threshold for detecting floor collisions (dot product with UP vector)
@export_range(0.5, 1.0, 0.01) var floor_detection_threshold: float = 0.9

# === STATE VARIABLES ===
var has_launched: bool = false
var is_sliding: bool = false
var boost_cooldown_timer: float = 0.0
var collision_grace_timer: float = 0.0
var post_bounce_timer: float = 0.0

# === TRACKING VARIABLES ===
var entity_id: int = 0
var floor_position_y: float = 0.0
var max_height_y: float = 0.0
var initial_bounce_position_y: float = 0.0 # Track the position where the bounce started

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
		
	# Initialize max_height_y to current position
	max_height_y = position.y
	floor_position_y = position.y
	initial_bounce_position_y = position.y
	
# Handle input for player actions
func _unhandled_input(event: InputEvent) -> void:
	# Check for boost input (Space key by default)
	if event.is_action_pressed("boost"):
		# Only allow boost if we're already in motion and not on cooldown
		if has_launched and boost_cooldown_timer <= 0.0:
			_try_boost()

# Main physics process
func _physics_process(delta: float) -> void:
	# Skip if not in motion
	if not has_launched and not is_sliding:
		return
	
	# Update timers and state
	_update_timers(delta)
	
	# Resolve motion for this frame
	var velocity_before_slide = _resolve_motion(delta)
	
	# Perform movement
	move_and_slide()
	
	# Update tracking variables
	_update_tracking_variables()
	
	# Handle collisions
	_handle_collisions(velocity_before_slide)
	
	# Round position to integer pixels to prevent subpixel flickering
	position = position.round()

# Update timers
func _update_timers(delta: float) -> void:
	if boost_cooldown_timer > 0.0:
		boost_cooldown_timer -= delta
	
	if collision_grace_timer > 0.0:
		collision_grace_timer -= delta
		
	if post_bounce_timer > 0.0:
		post_bounce_timer -= delta

# Resolve motion for this frame
func _resolve_motion(delta: float) -> Vector2:
	# Create motion context for this frame
	var motion_context = {
		# Entity information
		"entity_id": entity_id,
		"entity_type": "player",
		"player_node": self,
		
		# Position and physics
		"position": position,
		"velocity": velocity,
		"delta": delta,
		
		# State
		"is_on_floor": is_on_floor(),
		"has_launched": has_launched,
		"is_sliding": is_sliding,
		"skip_gravity": post_bounce_timer > 0.0,
		
		# Tracking
		"max_height_y": max_height_y,
		"floor_position_y": floor_position_y
	}
	
	# Apply motion physics via MotionSystem
	if motion_system and motion_system.has_method("resolve_frame_motion"):
		var motion_result = motion_system.resolve_frame_motion(motion_context)
		_apply_motion_result(motion_result)
	
	# Return velocity before slide for collision handling
	return velocity

# Apply the results from motion resolution
func _apply_motion_result(motion_result: Dictionary) -> void:
	if motion_result.has("velocity"):
		# If we're in post-bounce period, preserve our upward velocity
		if post_bounce_timer > 0.0 and velocity.y < 0:
			motion_result.velocity.y = velocity.y
		
		# If we're sliding, ensure Y velocity is zero
		if is_sliding:
			motion_result.velocity.y = 0.0
			
		velocity = motion_result.velocity
		
	if motion_result.has("has_launched"):
		has_launched = motion_result.has_launched
		
	if motion_result.has("is_sliding"):
		is_sliding = motion_result.is_sliding

# Update tracking variables
func _update_tracking_variables() -> void:
	# Update max_height_y if we've reached a higher point
	# In Godot, smaller Y values are higher up
	if position.y < max_height_y:
		max_height_y = position.y

# Handle collisions that occurred during move_and_slide
func _handle_collisions(velocity_before_slide: Vector2) -> void:
	# Skip collision handling if we're in the grace period
	if collision_grace_timer > 0.0:
		return
		
	var collision_count = get_slide_collision_count()
	for i in range(collision_count):
		var collision: KinematicCollision2D = get_slide_collision(i)
		if not collision:
			continue
			
		# Check if it's a floor collision (normal pointing sufficiently upwards)
		if _is_floor_collision(collision):
			_handle_floor_collision(collision, velocity_before_slide)
			# Handle only the first significant floor collision per frame
			break

# Check if a collision is with the floor
func _is_floor_collision(collision: KinematicCollision2D) -> bool:
	var normal = collision.get_normal()
	var dot_product = normal.dot(Vector2.UP)
	
	# Debug output
	if OS.is_debug_build():
		print("COLLISION - Normal: %s, Dot with UP: %.3f" % [normal, dot_product])
	
	# Using the configured threshold to account for minor slope variations
	if dot_product > floor_detection_threshold:
		if OS.is_debug_build():
			print("FLOOR COLLISION DETECTED in PlayerCharacter")
		return true
		
	return false

# Handle a floor collision
func _handle_floor_collision(collision: KinematicCollision2D, velocity_before_slide: Vector2) -> void:
	# Update floor position
	floor_position_y = position.y
	
	# Detect material type
	var material_type = _detect_material_type(collision)
	
	# Construct collision info
	var collision_info = {
		"entity_id": entity_id,
		"position": position,
		"normal": collision.get_normal(),
		"velocity": velocity_before_slide,
		"has_launched": has_launched,
		"is_sliding": is_sliding,
		"max_height_y": max_height_y,
		"floor_position_y": floor_position_y,
		"material": material_type,
		"player_node": self,
		"collider": collision.get_collider()
	}
	
	# Resolve collision with MotionSystem
	_resolve_collision_with_motion_system(collision_info)

# Detect the material type of a collision
func _detect_material_type(collision: KinematicCollision2D) -> String:
	var material_type = "default"
	
	if motion_system:
		var collision_material_system = motion_system.get_subsystem("CollisionMaterialSystem")
		if collision_material_system:
			# Create a preliminary collision info to pass to the material system
			var material_detection_info = {
				"collider": collision.get_collider(),
				"normal": collision.get_normal(),
				"position": position
			}
			material_type = collision_material_system.detect_material_from_collision(material_detection_info)
		else:
			# Fallback to local detection if CollisionMaterialSystem is not available
			material_type = _detect_floor_material_from_collider(collision.get_collider())
	else:
		# Fallback to local detection if motion_system is not available
		material_type = _detect_floor_material_from_collider(collision.get_collider())
		
	return material_type

# Resolve a collision using the MotionSystem
func _resolve_collision_with_motion_system(collision_info: Dictionary) -> void:
	if not motion_system or not motion_system.has_method("resolve_collision"):
		return
		
	var collision_result = motion_system.resolve_collision(collision_info)
	
	# Apply the collision result
	if collision_result.has("velocity"):
		velocity = collision_result.velocity
		
		# If we're bouncing (negative Y velocity), start timers
		if velocity.y < 0:
			collision_grace_timer = collision_grace_duration
			post_bounce_timer = post_bounce_duration
			
			# Reset max_height_y to current position at the start of a new bounce
			max_height_y = position.y
			initial_bounce_position_y = position.y
	
	# Update state from collision result
	if collision_result.has("has_launched"):
		has_launched = collision_result.has_launched
		
	if collision_result.has("is_sliding"):
		is_sliding = collision_result.is_sliding
		
	if collision_result.has("max_height_y"):
		max_height_y = collision_result.max_height_y

# Try to apply a boost using the BoostSystem
func _try_boost() -> void:
	# Get the boost system
	if not motion_system:
		return
		
	var boost_system = motion_system.get_subsystem("BoostSystem")
	if not boost_system:
		print("BoostSystem not found")
		return
	
	# Create state data for the boost
	var state_data = {
		"is_airborne": not is_on_floor(),
		"is_rising": velocity.y < 0,  # In Godot, negative Y is up
		"velocity": velocity,
		"position": position,
		"player_node": self  # Add reference to self for the boost system
	}
	
	# Try to apply the boost
	var result = boost_system.try_apply_boost(entity_id, "manual_air", state_data)
	
	# Apply the result if successful
	if result.has("success") and result["success"]:
		velocity = result["resulting_velocity"]
		boost_cooldown_timer = boost_cooldown_duration

# Fallback material detection method
# Only used if CollisionMaterialSystem is not available
# This is a legacy method that will eventually be removed
func _detect_floor_material_from_collider(collider) -> String:
	if not collider:
		return "default"
		
	# Check if the collider has a material_type property
	if collider.get("material_type"):
		return collider.material_type
		
	# Check if the collider is in specific groups
	if collider.is_in_group("ice"):
		return "ice"
	elif collider.is_in_group("mud"):
		return "mud"
	elif collider.is_in_group("rubber"):
		return "rubber"
		
	# Check the collider's name for material hints (least reliable method)
	var collider_name = collider.name.to_lower()
	if "ice" in collider_name:
		return "ice"
	elif "mud" in collider_name:
		return "mud"
	elif "rubber" in collider_name:
		return "rubber"
		
	# Fallback to default
	return "default"

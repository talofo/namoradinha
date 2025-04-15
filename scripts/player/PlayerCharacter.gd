class_name PlayerCharacter
extends CharacterBody2D

# BoostEffect is available globally via class_name

# === REFERENCES ===
var motion_system = null

# === STATE VARIABLES ===
var has_launched: bool = false
var is_sliding: bool = false
var boost_cooldown_timer: float = 0.0
var boost_cooldown_duration: float = 0.5  # Seconds between boosts
var collision_grace_timer: float = 0.0    # Timer to prevent immediate re-collision after bounce
var collision_grace_duration: float = 0.1  # Seconds to ignore collisions after a bounce
var post_bounce_timer: float = 0.0        # Timer to skip gravity after a bounce
var post_bounce_duration: float = 0.1     # Seconds to skip gravity after a bounce

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
	
	# Boost effect removed to fix flickering issue

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
		
	# Update timers
	if boost_cooldown_timer > 0.0:
		boost_cooldown_timer -= delta
	
	if collision_grace_timer > 0.0:
		collision_grace_timer -= delta
		
	if post_bounce_timer > 0.0:
		post_bounce_timer -= delta

	# Create motion context for this frame
	var motion_context = {
		# Entity information
		"entity_id": entity_id,
		"entity_type": "player",
		"player_node": self, # Added reference to self for resolver context

		# Position and physics
		"position": position,
		"velocity": velocity,
		"delta": delta,
		# Gravity is now handled internally by MotionSystem based on PhysicsConfig

		# State
		"is_on_floor": is_on_floor(),
		"has_launched": has_launched,
		"is_sliding": is_sliding,
		"skip_gravity": post_bounce_timer > 0.0, # Skip gravity if in post-bounce period

		# Tracking
		"max_height_y": max_height_y,
		"floor_position_y": floor_position_y
		# Material removed here, as it's primarily needed during collision resolution below
	}

	# Apply motion physics via MotionSystem (calculates intended velocity for this frame)
	var motion_result = {}
	if motion_system and motion_system.has_method("resolve_frame_motion"):
		motion_result = motion_system.resolve_frame_motion(motion_context)

	# Apply results from motion system
	if motion_result.has("velocity"):
		# If we're in post-bounce period, preserve our upward velocity
		if post_bounce_timer > 0.0 and velocity.y < 0:
			# Only take the X component from motion_result, keep our Y velocity
			motion_result.velocity.y = velocity.y
		
		# If we're sliding, ensure Y velocity is zero
		if is_sliding:
			motion_result.velocity.y = 0.0
			
		velocity = motion_result.velocity
	if motion_result.has("has_launched"):
		has_launched = motion_result.has_launched
	if motion_result.has("is_sliding"):
		is_sliding = motion_result.is_sliding
			
	# Store velocity *before* move_and_slide potentially modifies it
	var velocity_before_slide = velocity

	# Perform the actual movement and collision detection/response
	move_and_slide()
	
	# Update max_height_y if we've reached a higher point
	# In Godot, smaller Y values are higher up
	if position.y < max_height_y:
		max_height_y = position.y

	# Check for collisions that occurred during move_and_slide
	# Skip collision handling if we're in the grace period
	if collision_grace_timer <= 0.0:
		var collision_count = get_slide_collision_count()
		for i in range(collision_count):
			var collision: KinematicCollision2D = get_slide_collision(i)
			if collision:
				# Check if it's a floor collision (normal pointing sufficiently upwards)
				# Using a threshold slightly less than 1.0 to account for minor slope variations
				if collision.get_normal().dot(Vector2.UP) > 0.9: 
					floor_position_y = position.y # Update floor position on contact
					
					# Detect material type from collider
					var material_type = _detect_floor_material_from_collider(collision.get_collider())
					
					# Construct collision info using pre-slide velocity and collision data
					var collision_info = {
						"entity_id": entity_id,
						"position": position, # Use current position after move_and_slide
						"normal": collision.get_normal(),
						"velocity": velocity_before_slide, # Use velocity BEFORE move_and_slide
						"has_launched": has_launched,
						"is_sliding": is_sliding,
						"max_height_y": max_height_y,
						"floor_position_y": floor_position_y,
						"material": material_type,
						"player_node": self # Added player_node reference
					}

					# Let MotionSystem handle collision response using pre-slide velocity
					if motion_system and motion_system.has_method("resolve_collision"):
						var collision_result = motion_system.resolve_collision(collision_info)

						# Apply the collision result directly
						if collision_result.has("velocity"):
							velocity = collision_result.velocity # OVERWRITE velocity modified by move_and_slide
							
							# If we're bouncing (negative Y velocity), start the collision grace timer and post-bounce timer
							if velocity.y < 0: 
								collision_grace_timer = collision_grace_duration
								post_bounce_timer = post_bounce_duration
								# Reset max_height_y to current position at the start of a new bounce
								# This ensures we track the maximum height reached during this bounce
								max_height_y = position.y
								initial_bounce_position_y = position.y
							
							# Removed redundant check: velocity.y = 0.0 for sliding.
							# The BounceCalculator/CollisionMotionResolver should provide the correct velocity vector.
								
						if collision_result.has("has_launched"):
							has_launched = collision_result.has_launched
						if collision_result.has("is_sliding"):
							is_sliding = collision_result.is_sliding
						if collision_result.has("max_height_y"):
							max_height_y = collision_result.max_height_y
							
					# Handle only the first significant floor collision per frame
					break 

	# Round position to integer pixels to prevent subpixel flickering
	position = position.round() 

# === VISUAL EFFECTS ===
var boost_effect = null # Will be a BoostEffect instance

# Create a boost effect for visual feedback
func _create_boost_effect() -> void:
	boost_effect = BoostEffect.new()
	boost_effect.name = "BoostEffect"
	add_child(boost_effect)

# Show the boost effect with the specified boost type
func _show_boost_effect(direction: Vector2, boost_type: String = "manual_air") -> void:
	if not boost_effect:
		return
		
	# Show the boost effect with the specified direction and type
	boost_effect.show_effect(direction, boost_type)

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
		# Visual effect removed to fix flickering issue

# Detect the material of the floor at the current position
# This function attempts to determine the material type from the collider
# by checking for specific properties or groups.
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
		
	# Check the collider's name for material hints
	var collider_name = collider.name.to_lower()
	if "ice" in collider_name:
		return "ice"
	elif "mud" in collider_name:
		return "mud"
	elif "rubber" in collider_name:
		return "rubber"
		
	# Fallback to default
	return "default"

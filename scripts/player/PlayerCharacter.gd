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
		
	# DEBUG: Print initial velocity at the start of the frame
	print("[DEBUG] Start of frame velocity: ", velocity)
		
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
			print("[DEBUG] Preserving upward velocity during post-bounce: ", velocity.y)
			
		velocity = motion_result.velocity
		# DEBUG: Print velocity after motion system resolution
		print("[DEBUG] After motion_system.resolve_frame_motion velocity: ", velocity)
	if motion_result.has("has_launched"):
		has_launched = motion_result.has_launched
	if motion_result.has("is_sliding"):
		is_sliding = motion_result.is_sliding
			
	# Store velocity *before* move_and_slide potentially modifies it
	var velocity_before_slide = velocity
	# DEBUG: Print velocity before move_and_slide
	print("[DEBUG] Before move_and_slide velocity: ", velocity_before_slide)

	# Perform the actual movement and collision detection/response
	move_and_slide()
	
	# Update max_height_y if we've reached a higher point
	# In Godot, smaller Y values are higher up
	if position.y < max_height_y:
		max_height_y = position.y
		print("[DEBUG] Updated max_height_y to: ", max_height_y) # DEBUG PRINT
		print("[DEBUG] Current bounce height: ", floor_position_y - max_height_y) # DEBUG PRINT

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
					print("[DEBUG] Floor collision detected. floor_position_y set to: ", floor_position_y) # DEBUG PRINT
					
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
						"material": _detect_floor_material_from_collider(collision.get_collider()),
						"player_node": self # Added player_node reference
					}

					# Let MotionSystem handle collision response using pre-slide velocity
					if motion_system and motion_system.has_method("resolve_collision"):
						print("[PlayerCharacter._physics_process] Floor collision detected. Pre-slide vel: ", velocity_before_slide, " Normal: ", collision.get_normal()) # DEBUG PRINT
						print("[PlayerCharacter._physics_process] Calling motion_system.resolve_collision with info: ", collision_info) # DEBUG PRINT
						var collision_result = motion_system.resolve_collision(collision_info)
						print("[PlayerCharacter._physics_process] Collision result received: ", collision_result) # DEBUG PRINT

						# Apply the collision result directly
						if collision_result.has("velocity"):
							print("[PlayerCharacter._physics_process] Applying velocity from result: ", collision_result.velocity) # DEBUG PRINT
							velocity = collision_result.velocity # OVERWRITE velocity modified by move_and_slide
							
							# If we're bouncing (negative Y velocity), start the collision grace timer and post-bounce timer
							if velocity.y < 0:
								collision_grace_timer = collision_grace_duration
								post_bounce_timer = post_bounce_duration
								# Reset max_height_y to current position at the start of a new bounce
								# This ensures we track the maximum height reached during this bounce
								max_height_y = position.y
								initial_bounce_position_y = position.y
								
								# Print debug info about bounce height
								print("[DEBUG] PlayerCharacter: Starting new bounce. Resetting max_height_y to ", max_height_y)
								print("[DEBUG] PlayerCharacter: Current bounce height is 0 (just started)")
								print("[PlayerCharacter._physics_process] Starting collision grace period: ", collision_grace_duration, "s") # DEBUG PRINT
								print("[PlayerCharacter._physics_process] Starting post-bounce period: ", post_bounce_duration, "s") # DEBUG PRINT
								print("[PlayerCharacter._physics_process] Reset max_height_y to: ", max_height_y) # DEBUG PRINT
								# DEBUG: Print final velocity after bounce
								print("[DEBUG] Final velocity after bounce: ", velocity)
							
							# Ensure Y component is zero when sliding
							if collision_result.has("is_sliding") and collision_result.is_sliding:
								velocity.y = 0.0
								
						if collision_result.has("has_launched"):
							has_launched = collision_result.has_launched
						if collision_result.has("is_sliding"):
							is_sliding = collision_result.is_sliding
						if collision_result.has("max_height_y"):
							max_height_y = collision_result.max_height_y
							print("[DEBUG] max_height_y updated from collision result to: ", max_height_y) # DEBUG PRINT
							
					# Handle only the first significant floor collision per frame
					break 

	# Round position to integer pixels to prevent subpixel flickering
	position = position.round() 

# Get the current bounce count from the BounceSystem
func get_bounce_count() -> int:
	if motion_system and motion_system.has_method("get_subsystem"):
		var bounce_system = motion_system.get_subsystem("BounceSystem")
		if bounce_system and bounce_system.has_method("get_bounce_count"):
			return bounce_system.get_bounce_count(entity_id)
	return -1
	
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
		print("Boost applied! New velocity: ", velocity)

# Detect the material of the floor at the current position
# TODO: Implement logic to detect material based on the actual floor collider.
#       This will likely involve getting the collider via get_floor_collider(),
#       finding an attached script (e.g., GroundMaterialInfo.gd) on it or its owner,
#       and reading a 'material_name' property from that script.
#       The returned name should correspond to a key in PhysicsConfig.material_properties.
func _detect_floor_material_from_collider(_collider) -> String:
	# TODO: Implement actual material detection based on the collider
	# Example placeholder:
	# if _collider and _collider.has_method("get_physics_material_override"):
	#     var material = collider.get_physics_material_override()
	#     if material and material.has_meta("material_name"):
	#         return material.get_meta("material_name")
	# Or check script attached to collider/owner
	
	# Fallback to default
	return "default"

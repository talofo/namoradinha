extends CharacterBody2D

# === TUNABLE VARIABLES ===
@export var gravity: float = 1200.0
@export var first_bounce_ratio: float = 0.8  # First bounce will be 80% of max launch height
@export var subsequent_bounce_ratio: float = 0.6  # Each subsequent bounce will be 60% of previous
@export var ground_friction: float = 0.02

# === STATE VARIABLES ===
var has_launched: bool = false
var bounce_count: int = 0
var is_sliding: bool = false

# Height tracking
var launch_position_y: float = 0.0  # Y position at launch
var floor_position_y: float = 0.0   # Y position of the floor
var max_height_y: float = 0.0       # Lowest Y value reached (highest point)
var current_target_height: float = 0.0  # Target height for current bounce cycle
var launch_velocity: Vector2 = Vector2.ZERO  # Store original launch velocity

func launch(direction: Vector2) -> void:
	velocity = direction
	launch_velocity = direction
	has_launched = true
	is_sliding = false
	bounce_count = 0
	
	# Record our starting position
	launch_position_y = position.y
	floor_position_y = position.y
	
	# Initialize max height to current position
	max_height_y = position.y
	current_target_height = 0.0  # Will be calculated after max height is reached
	
	print("Launched from Y:", launch_position_y)
	print("Launch velocity:", launch_velocity)

func _physics_process(delta: float) -> void:
	# Only process if flying or sliding
	if not has_launched and not is_sliding:
		return
		
	# Track maximum height reached (minimum Y value since Y increases downward)
	if has_launched and position.y < max_height_y:
		max_height_y = position.y
		
	# Apply gravity if flying
	if has_launched:
		velocity.y += gravity * delta
		
	if is_on_floor():
		# Update floor position if different (for slopes or varying terrain)
		floor_position_y = position.y
		
		if has_launched and velocity.y >= 0:
			apply_bounce()
		elif is_sliding:
			apply_slide()
			
	move_and_slide()

func apply_bounce() -> void:
	bounce_count += 1
	
	# Calculate the max height achieved relative to floor
	var max_height_reached = floor_position_y - max_height_y
	print("BOUNCE #", bounce_count)
	print("  Floor Y:", floor_position_y)
	print("  Peak Y:", max_height_y)
	print("  Max height reached:", max_height_reached)
	
	# Calculate target height for this bounce
	var target_height = 0.0
	if bounce_count == 1:
		# First bounce - relative to max launch height
		target_height = max_height_reached * first_bounce_ratio
		current_target_height = target_height
	else:
		# Subsequent bounces - relative to previous bounce target
		target_height = current_target_height * subsequent_bounce_ratio
		current_target_height = target_height
	
	print("  Target bounce height:", target_height)
	
	# Calculate required velocity to reach that height
	# Using physics formula: v = sqrt(2 * g * h)
	var bounce_velocity = sqrt(2 * gravity * target_height)
	print("  Required velocity:", bounce_velocity)
	
	if target_height < 5.0:
		velocity.y = 0.0
		has_launched = false
		is_sliding = true
		print("Stopped bouncing. Begin sliding.")
	else:
		velocity.y = -bounce_velocity
		
		# Reset max height tracking for the next bounce
		max_height_y = position.y
		
	# Maintain horizontal speed with consistent decay - using the original approach
	# This preserves more of the forward momentum for better sliding
	velocity.x = velocity.x * 0.9

func apply_slide() -> void:
	# Using the same slide logic as your original code
	velocity.x = lerp(velocity.x, 0.0, ground_friction)
	if abs(velocity.x) < 5.0:
		velocity.x = 0.0
		is_sliding = false
		print("Stopped sliding.")

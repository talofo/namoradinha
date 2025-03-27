extends CharacterBody2D

# === TUNABLE VARIABLES ===
@export var gravity: float = 1000.0
@export var bounce_falloff: float = 0.7  # Controls how fast bounce height decays
@export var ground_friction: float = 0.03  # Controls how fast the player slows down on ground

# === STATE VARIABLES ===
var has_launched: bool = false
var bounce_count: int = 0
var is_sliding: bool = false


func launch(direction: Vector2) -> void:
	velocity = direction
	has_launched = true
	is_sliding = false
	bounce_count = 0


func _physics_process(delta: float) -> void:
	# Only process if flying or sliding
	if not has_launched and not is_sliding:
		return

	# Apply gravity if flying
	if has_launched:
		velocity.y += gravity * delta

	if is_on_floor():
		if has_launched and velocity.y >= 0:
			apply_bounce()
		elif is_sliding:
			apply_slide()

	move_and_slide()


func apply_bounce() -> void:
	bounce_count += 1

	var falloff: float = pow(bounce_falloff, bounce_count)
	var base_bounce: float = max(abs(velocity.y), 800.0)
	var bounce_force: float = base_bounce * falloff

	if bounce_force < 100.0:
		velocity.y = 0.0
		has_launched = false
		is_sliding = true
		print("Stopped bouncing. Begin sliding.")
	else:
		velocity.y = -bounce_force
		print("BOUNCE #", bounce_count, " Force: ", bounce_force)


func apply_slide() -> void:
	velocity.x = lerp(velocity.x, 0.0, ground_friction)

	if abs(velocity.x) < 5.0:
		velocity.x = 0.0
		is_sliding = false
		print("Stopped sliding.")

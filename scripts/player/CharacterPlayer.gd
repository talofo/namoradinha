extends CharacterBody2D

# === TUNABLE VARIABLES ===
@export var gravity: float = 1000.0
@export var bounce_falloff: float = 0.7  # Controls how fast bounce height decays

# === STATE VARIABLES ===
var has_launched: bool = false
var bounce_count: int = 0


func launch(direction: Vector2) -> void:
	velocity = direction
	has_launched = true
	bounce_count = 0


func _physics_process(delta: float) -> void:
	if not has_launched:
		return

	velocity.y += gravity * delta

	if is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, 0.2)

		if velocity.y >= 0:
			apply_bounce()

	move_and_slide()


func apply_bounce() -> void:
	bounce_count += 1

	var falloff: float = pow(bounce_falloff, bounce_count)
	var base_bounce: float = max(abs(velocity.y), 800.0)
	var bounce_force: float = base_bounce * falloff

	if bounce_force < 100.0:
		velocity.y = 0.0
		has_launched = false
		print("Stopped bouncing.")
	else:
		velocity.y = -bounce_force
		print("BOUNCE #", bounce_count, " Force: ", bounce_force)

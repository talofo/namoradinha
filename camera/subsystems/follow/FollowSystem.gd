class_name FollowSystem
extends ICameraSubsystem

var _camera: Camera2D
var _config: CameraConfig
var _target: Node2D
var _previous_position: Vector2
var _smoothed_target_y: float = 0.0 # Variable to store the smoothly interpolated target Y

func _init(camera: Camera2D, config: CameraConfig) -> void:
	_camera = camera
	_config = config
	_previous_position = Vector2.ZERO

func initialize() -> void:
	_camera.position_smoothing_enabled = false # Disable built-in smoothing
	_camera.position_smoothing_speed = _config.smoothing_speed
	# Remove process callback setting, CameraSystem handles calling update in _physics_process
	_camera.enabled = false

func update(_delta: float) -> void:
	if not _target or not _camera.enabled:
		return

	# --- Calculate Ideal Target Y ---
	var viewport_size = _camera.get_viewport().get_visible_rect().size
	var ground_viewport_position = viewport_size.y * _config.ground_viewport_ratio
	var locked_camera_y = -(viewport_size.y / 2) + ground_viewport_position
	var ideal_target_y: float

	# Determine if the camera should follow the player's Y or lock
	if _target.global_position.y < locked_camera_y - viewport_size.y * _config.follow_height_threshold:
		ideal_target_y = _target.global_position.y # Follow player exactly if high enough
	else:
		ideal_target_y = locked_camera_y # Lock Y position otherwise

	# --- Smooth the Target Y ---
	var vertical_weight = clamp(_config.vertical_smoothing_speed * _delta, 0.0, 1.0)
	_smoothed_target_y = lerpf(_smoothed_target_y, ideal_target_y, vertical_weight)

	# --- Construct Final Target Position ---
	# Use player's current X and the smoothed target Y
	var final_target_position = Vector2(_target.global_position.x, _smoothed_target_y)

	# --- Smooth Camera Towards Final Target ---
	var camera_weight = clamp(_config.smoothing_speed * _delta, 0.0, 1.0)
	_camera.position = _camera.position.lerp(final_target_position, camera_weight)

func set_target(target: Node2D) -> void:
	_target = target # Keep storing the target reference if needed elsewhere
	if _target:
		_camera.enabled = true
		_camera.make_current()
		# Cannot set target_node_path, Camera2D doesn't have it.
		# Re-enable manual initial adjustment.
		_adjust_initial_camera_position()

# Removed calculate_target_position as logic is now in update()

func _adjust_initial_camera_position() -> void:
	if not _target:
		return

	var viewport_size = _camera.get_viewport().get_visible_rect().size
	var ground_viewport_position = viewport_size.y * _config.ground_viewport_ratio
	var camera_y_position = -(viewport_size.y / 2) + ground_viewport_position

	# Set initial camera position and smoothed target Y
	_camera.position.x = _target.global_position.x
	_camera.position.y = camera_y_position
	_smoothed_target_y = camera_y_position # Initialize smoothed Y to the initial locked position

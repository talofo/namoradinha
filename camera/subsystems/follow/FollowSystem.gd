class_name FollowSystem
extends ICameraSubsystem

var _camera: Camera2D
var _config: CameraConfig
var _target: Node2D
var _previous_position: Vector2

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

	# Calculate the target position using the existing logic
	var target_position = calculate_target_position()

	# Smoothly interpolate towards the target position using lerp
	# Calculate weight based on smoothing speed and delta time, clamped between 0 and 1
	var weight = clamp(_config.smoothing_speed * _delta, 0.0, 1.0)
	_camera.position = _camera.position.lerp(target_position, weight)

	# Remove the limit_bottom setting as lerp handles the target position
	# _camera.limit_bottom = int(camera_min_y_world)

func set_target(target: Node2D) -> void:
	_target = target # Keep storing the target reference if needed elsewhere
	if _target:
		_camera.enabled = true
		_camera.make_current()
		# Cannot set target_node_path, Camera2D doesn't have it.
		# Re-enable manual initial adjustment.
		_adjust_initial_camera_position()

func calculate_target_position() -> Vector2:
	if not _target:
		return Vector2.ZERO
		
	var viewport_size = _camera.get_viewport().get_visible_rect().size
	var ground_viewport_position = viewport_size.y * _config.ground_viewport_ratio
	var camera_y_position = -(viewport_size.y / 2) + ground_viewport_position
	
	var target_position = _target.global_position
	
	if _target.global_position.y < camera_y_position - viewport_size.y * _config.follow_height_threshold:
		target_position.y = _target.global_position.y
	else:
		target_position.y = camera_y_position
		
	return target_position

func _adjust_initial_camera_position() -> void:
	if not _target:
		return
		
	var viewport_size = _camera.get_viewport().get_visible_rect().size
	var ground_viewport_position = viewport_size.y * _config.ground_viewport_ratio
	var camera_y_position = -(viewport_size.y / 2) + ground_viewport_position
	
	_camera.position.x = _target.global_position.x
	_camera.position.y = camera_y_position

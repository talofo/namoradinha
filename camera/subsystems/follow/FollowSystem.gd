class_name FollowSystem
extends ICameraSubsystem

var _camera: Camera2D
var _config: CameraConfig
var _target: Node2D
var _previous_position: Vector2
var _smoothed_target_y: float = 0.0

func _init(camera: Camera2D, config: CameraConfig) -> void:
	_camera = camera
	_config = config
	_previous_position = Vector2.ZERO

func initialize() -> void:
	_camera.position_smoothing_enabled = false # Disable built-in smoothing
	_camera.position_smoothing_speed = _config.smoothing_speed
	_camera.enabled = false

func update(delta: float) -> void:
	if not is_instance_valid(_target) or not (is_instance_valid(_camera) and _camera.enabled):
		return

	# --- Get Target Velocity (Safely) ---
	var target_velocity: Vector2 = Vector2.ZERO
	if _target and "velocity" in _target:
		var vel = _target.velocity
		if typeof(vel) == TYPE_VECTOR2:
			target_velocity = vel
		else:
			Debug.print("FOLLOW_SYSTEM", "WARNING: Target 'velocity' property is not a Vector2.")
			return
	else:
		Debug.print("FOLLOW_SYSTEM", "WARNING: Target does not have a 'velocity' property.")
		return

	# --- Calculate Base Look-Ahead Factors (Potentially Scaled) ---
	var current_horizontal_lookahead_factor = _config.horizontal_lookahead_factor
	var current_vertical_lookahead_factor = _config.vertical_lookahead_factor

	if _config.enable_lookahead_speed_scaling:
		var speed = target_velocity.length()
		var scale_ratio = inverse_lerp(_config.lookahead_scale_min_speed, _config.lookahead_scale_max_speed, speed)
		scale_ratio = clamp(scale_ratio, 0.0, 1.0)
		var multiplier = lerp(1.0, _config.lookahead_max_scale_multiplier, scale_ratio)
		current_horizontal_lookahead_factor *= multiplier
		current_vertical_lookahead_factor *= multiplier

	# --- Calculate Look-Ahead Offsets ---
	var lookahead_offset_x: float = target_velocity.x * current_horizontal_lookahead_factor
	var lookahead_offset_y: float = target_velocity.y * current_vertical_lookahead_factor

	# --- Calculate Anticipation Offsets ---
	var downward_anticipation_offset: float = 0.0
	var upward_anticipation_offset: float = 0.0
	
	if target_velocity.y > _config.vertical_velocity_threshold:
		var calculated_down_anticipation = target_velocity.y * _config.downward_anticipation_factor
		downward_anticipation_offset = min(calculated_down_anticipation, _config.max_downward_anticipation_offset)
	elif target_velocity.y < -_config.vertical_velocity_threshold:
		var calculated_up_anticipation = abs(target_velocity.y) * _config.upward_anticipation_factor
		upward_anticipation_offset = -min(calculated_up_anticipation, _config.max_upward_anticipation_offset)

	# --- Calculate Ideal Target Y ---
	var viewport_size = _camera.get_viewport().get_visible_rect().size
	var ground_viewport_position = viewport_size.y * _config.ground_viewport_ratio
	var locked_camera_y = -(viewport_size.y / 2) + ground_viewport_position
	var ideal_target_y: float

	# Determine if the camera should follow the player's Y or lock
	var is_following_y = _target.global_position.y < locked_camera_y - viewport_size.y * _config.follow_height_threshold
	if is_following_y:
		# Follow player: Apply general vertical look-ahead AND specific up/down anticipation
		ideal_target_y = _target.global_position.y + lookahead_offset_y + downward_anticipation_offset + upward_anticipation_offset
	else:
		# Lock Y position: Do NOT apply vertical look-ahead or anticipation here
		ideal_target_y = locked_camera_y

	# --- Smooth the Target Y ---
	var vertical_weight = clamp(_config.vertical_smoothing_speed * delta, 0.0, 1.0)
	_smoothed_target_y = lerpf(_smoothed_target_y, ideal_target_y, vertical_weight)

	# --- Construct Final Target Position ---
	var final_target_position = Vector2(_target.global_position.x + lookahead_offset_x, _smoothed_target_y)

	# --- Smooth Camera Towards Final Target ---
	var camera_weight = clamp(_config.smoothing_speed * delta, 0.0, 1.0)
	_camera.position = _camera.position.lerp(final_target_position, camera_weight)

func set_target(target: Node2D) -> void:
	if is_instance_valid(target):
		_target = target 
		if is_instance_valid(_camera):
			_camera.enabled = true
			_camera.make_current()
		else:
			Debug.print("CAMERA", "ERROR: FollowSystem _camera instance is invalid!")
			return
		_adjust_initial_camera_position()

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

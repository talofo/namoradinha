class_name ZoomSystem
extends ICameraSubsystem

var _camera: Camera2D
var _config: CameraConfig
var _target: Node2D
var _is_initialized: bool = false

# --- Initialization ---

func _init(camera: Camera2D, config: CameraConfig) -> void:
	_camera = camera
	_config = config

func initialize() -> void:
	if not _camera or not _config:
		Debug.print("ZOOM_SYSTEM", "ERROR: Camera or Config not provided during init.")
		return
	
	_camera.zoom = _config.default_zoom
	_is_initialized = true
	Debug.print("ZOOM_SYSTEM", "Initialized")

func set_target(target: Node2D) -> void:
	_target = target
	if not _target:
		Debug.print("ZOOM_SYSTEM", "WARNING: Target node is null.")

# --- Core Logic ---

func update(delta: float) -> void:
	if not _is_initialized or not _target or not _camera.enabled:
		return

	# --- Get Target Velocity (Safely) ---
	var target_velocity: Vector2 = Vector2.ZERO
	if "velocity" in _target:
		var vel = _target.velocity
		if typeof(vel) == TYPE_VECTOR2:
			target_velocity = vel
		else:
			Debug.print("ZOOM_SYSTEM", "WARNING: Target 'velocity' property is not a Vector2.")
			return
	else:
		Debug.print("ZOOM_SYSTEM", "WARNING: Target does not have a 'velocity' property.")
		return
			
	# --- Calculate Target Zoom ---
	var speed: float = abs(target_velocity.x) 
	var target_zoom_value: float = remap(speed, 
										 _config.zoom_min_speed_threshold, 
										 _config.zoom_max_speed_threshold, 
										 _config.min_zoom,
										 _config.max_zoom)
	
	# Clamp the zoom value to prevent extreme zooming
	target_zoom_value = clamp(target_zoom_value, _config.min_zoom, _config.max_zoom)
	
	var target_zoom: Vector2 = Vector2(target_zoom_value, target_zoom_value)

	# --- Smooth Camera Zoom ---
	if not _camera.zoom.is_equal_approx(target_zoom):
		var zoom_weight: float = clamp(_config.zoom_smoothing_speed * delta, 0.0, 1.0)
		_camera.zoom = _camera.zoom.lerp(target_zoom, zoom_weight)

class_name ZoomSystem
extends ICameraSubsystem

var _camera: Camera2D
var _config: CameraConfig
var _target: Node2D
var _is_initialized: bool = false

# Custom zoom variables
var _custom_zoom_active: bool = false
var _custom_zoom_target: Vector2 = Vector2.ONE
var _custom_zoom_duration: float = 0.0
var _custom_zoom_timer: float = 0.0

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

# --- Custom Zoom API ---

# Set a custom zoom level for a specific duration
func set_custom_zoom(zoom_level: float, duration: float = 1.0) -> void:
	if not _is_initialized or not _camera:
		Debug.print("ZOOM_SYSTEM", "ERROR: Cannot set custom zoom, system not initialized.")
		return
		
	_custom_zoom_active = true
	_custom_zoom_target = Vector2(zoom_level, zoom_level)
	_custom_zoom_duration = duration
	_custom_zoom_timer = 0.0
	Debug.print("ZOOM_SYSTEM", "Custom zoom set: %f for %f seconds" % [zoom_level, duration])

# Clear custom zoom and return to velocity-based zooming
func clear_custom_zoom() -> void:
	_custom_zoom_active = false
	Debug.print("ZOOM_SYSTEM", "Custom zoom cleared")

# --- Core Logic ---

func update(delta: float) -> void:
	if not _is_initialized or not _camera.enabled:
		return
		
	# Handle custom zoom if active
	if _custom_zoom_active:
		_custom_zoom_timer += delta
		if _custom_zoom_timer >= _custom_zoom_duration:
			_custom_zoom_active = false
			Debug.print("ZOOM_SYSTEM", "Custom zoom duration ended")
		else:
			var zoom_weight = clamp(_config.zoom_smoothing_speed * delta, 0.0, 1.0)
			_camera.zoom = _camera.zoom.lerp(_custom_zoom_target, zoom_weight)
			return
	
	# Skip velocity-based zoom if target is invalid
	if not _target:
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

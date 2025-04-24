class_name CameraSystem
extends Node2D

signal camera_moved(camera_position: Vector2, camera_zoom: Vector2)

@onready var camera: Camera2D = $Camera2D

@export var config: CameraConfig
var _follow_system: FollowSystem
var _zoom_system: ZoomSystem
var _slow_motion_system: SlowMotionSystem
var _previous_position: Vector2
var _is_initialized: bool = false

func _ready() -> void:
	if not _is_initialized:
		initialize_system()
		
	# Connect to global signals
	if GlobalSignals.player_spawned.is_connected(_on_player_spawned):
		GlobalSignals.player_spawned.disconnect(_on_player_spawned)
	# Defer the connection to ensure it happens after the signal might have been emitted during initialization
	GlobalSignals.player_spawned.connect(_on_player_spawned, CONNECT_DEFERRED) 
	
	# Enable debug logging for camera system
	if OS.is_debug_build():
		Debug.toggle_system("CAMERA", true)
		Debug.print("CAMERA", "Camera system initialized")

func initialize_system() -> void:
	if not config:
		Debug.print("CAMERA", "WARNING: CameraConfig resource not assigned to CameraSystem in the editor!") 
		config = CameraConfig.new() 
		Debug.print("CAMERA", "WARNING: Using default CameraConfig values.")
		
	# Instantiate subsystems
	_follow_system = FollowSystem.new(camera, config)
	_zoom_system = ZoomSystem.new(camera, config)
	_slow_motion_system = SlowMotionSystem.new(config)
	
	# Add the slow motion system's internal timer to the scene tree
	if _slow_motion_system and _slow_motion_system.has_method("get_timer"):
		var timer = _slow_motion_system.get_timer()
		if timer and not timer.is_inside_tree():
			add_child(timer)
	else:
		Debug.print("CAMERA", "ERROR: Could not access or add SlowMotionSystem's timer!")

	# Initialize subsystems
	_follow_system.initialize()
	_zoom_system.initialize()
	_slow_motion_system.initialize()
	
	_previous_position = Vector2.ZERO
	_is_initialized = true
	Debug.print("CAMERA", "Initialized successfully with Follow, Zoom, and SlowMotion subsystems")

func _physics_process(delta: float) -> void:
	if not _is_initialized:
		return
		
	# Update subsystems
	if _follow_system:
		_follow_system.update(delta)
	if _zoom_system:
		_zoom_system.update(delta)
	if _slow_motion_system:
		_slow_motion_system.update(delta)
	
	# Emit signal if camera position or zoom changed
	if camera.position != _previous_position or not camera.zoom.is_equal_approx(config.default_zoom): 
		camera_moved.emit(camera.position, camera.zoom)
		_previous_position = camera.position

func _on_player_spawned(player_node: Node2D) -> void:
	if not is_instance_valid(player_node):
		Debug.print("CAMERA", "ERROR: Received invalid player_node instance in _on_player_spawned!") 
		return
		
	if not _is_initialized:
		Debug.print("CAMERA", "Initializing systems because player spawned before ready.") 
		initialize_system() 
		
	# Set target for all relevant subsystems
	if _follow_system: 
		_follow_system.set_target(player_node)
	else:
		Debug.print("CAMERA", "ERROR: Follow system not initialized, cannot set target.")
		
	if _zoom_system:
		_zoom_system.set_target(player_node)
	else:
		Debug.print("CAMERA", "ERROR: Zoom system not initialized, cannot set target.")
		
	if _slow_motion_system:
		_slow_motion_system.set_target(player_node)
	else:
		Debug.print("CAMERA", "ERROR: SlowMotion system not initialized, cannot set target.")


# --- Public API for Triggering Slow Motion ---

func trigger_slow_motion(duration: float = -1.0, time_scale_factor: float = -1.0) -> void:
	if _slow_motion_system:
		_slow_motion_system.activate_slow_motion(duration, time_scale_factor)
	else:
		Debug.print("CAMERA", "ERROR: Cannot trigger slow motion, system not initialized.")

func stop_slow_motion() -> void:
	if _slow_motion_system:
		_slow_motion_system.deactivate_slow_motion()
	else:
		Debug.print("CAMERA", "ERROR: Cannot stop slow motion, system not initialized.")

func is_slow_motion_active() -> bool:
	if _slow_motion_system:
		return _slow_motion_system.is_slow_motion_active()
	return false


# --- Custom Zoom API ---

func set_custom_zoom(zoom_level: float, duration: float = 1.0) -> void:
	if _zoom_system:
		_zoom_system.set_custom_zoom(zoom_level, duration)
	else:
		Debug.print("CAMERA", "ERROR: Cannot set custom zoom, system not initialized.")

func clear_custom_zoom() -> void:
	if _zoom_system:
		_zoom_system.clear_custom_zoom()
	else:
		Debug.print("CAMERA", "ERROR: Cannot clear custom zoom, system not initialized.")

# --- Accessors ---

func get_camera_position() -> Vector2:
	return camera.position if camera else Vector2.ZERO

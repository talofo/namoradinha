class_name SlowMotionSystem
extends ICameraSubsystem

var _config: CameraConfig
var _is_active: bool = false
var _original_time_scale: float = 1.0
var _slowmo_timer: Timer

# --- Initialization ---

func _init(config: CameraConfig) -> void:
	_config = config
	# Create a Timer node internally. It needs to be added to the scene tree to function.
	_slowmo_timer = Timer.new()
	_slowmo_timer.one_shot = true
	_slowmo_timer.timeout.connect(_on_slowmo_timer_timeout)

func initialize() -> void:
	if not _config:
		Debug.print("SLOWMO_SYSTEM", "ERROR: Config not provided during init.")
		return
	# Ensure timer is added to the tree by the owner (CameraSystem)
	if not _slowmo_timer.is_inside_tree():
		Debug.print("SLOWMO_SYSTEM", "WARNING: Timer node not added to scene tree by owner. Slow motion duration will not work.")
	Debug.print("SLOWMO_SYSTEM", "Initialized")
	
# Get the timer instance for the CameraSystem to add to the scene tree
func get_timer() -> Timer:
	return _slowmo_timer

# Required by ICameraSubsystem, but might not be needed if target isn't relevant
func set_target(_target: Node2D) -> void:
	pass 

# Required by ICameraSubsystem, but might not be needed if no per-frame logic
func update(_delta: float) -> void:
	# Can be used for effects that evolve during slow motion if needed
	pass 

# --- Public API ---

func activate_slow_motion(duration: float = -1.0, time_scale_factor: float = -1.0) -> void:
	if _is_active:
		# Optionally restart timer or ignore, for now ignore reactivation
		Debug.print("SLOWMO_SYSTEM", "Slow motion already active.")
		return

	var factor = time_scale_factor if time_scale_factor > 0 else _config.default_slowmo_factor
	var dur = duration if duration > 0 else _config.default_slowmo_duration

	if factor <= 0 or factor >= 1.0:
		Debug.print("SLOWMO_SYSTEM", "ERROR: Invalid time_scale_factor: %f. Must be > 0 and < 1.0." % factor)
		return

	_original_time_scale = Engine.time_scale # Store current (should be 1.0)
	Engine.time_scale = factor
	_is_active = true
	Debug.print("SLOWMO_SYSTEM", "Activated. Time scale: %f" % Engine.time_scale)

	# Start timer only if duration is positive
	if dur > 0:
		_slowmo_timer.wait_time = dur / factor # Adjust timer duration by the time scale factor
		_slowmo_timer.start()
		Debug.print("SLOWMO_SYSTEM", "Timer started for adjusted duration: %f seconds" % _slowmo_timer.wait_time)
	else:
		Debug.print("SLOWMO_SYSTEM", "Activated indefinitely (manual deactivation required).")


func deactivate_slow_motion() -> void:
	if not _is_active:
		return

	Engine.time_scale = _original_time_scale # Restore original
	_is_active = false
	_slowmo_timer.stop() # Ensure timer is stopped if deactivated manually
	Debug.print("SLOWMO_SYSTEM", "Deactivated. Time scale restored to: %f" % Engine.time_scale)

func is_slow_motion_active() -> bool:
	return _is_active

# --- Signal Handlers ---

func _on_slowmo_timer_timeout() -> void:
	Debug.print("SLOWMO_SYSTEM", "Timer timed out.")
	deactivate_slow_motion()

# --- Cleanup ---
# Optional: Ensure time scale is reset if the system is destroyed while active
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _is_active:
			Engine.time_scale = _original_time_scale
			Debug.print("SLOWMO_SYSTEM", "WARNING: Resetting time scale during predelete.")
		if _slowmo_timer and _slowmo_timer.is_inside_tree():
			_slowmo_timer.queue_free() # Clean up the timer node

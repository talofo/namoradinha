# camera/CameraManager.gd
# Handles camera follow logic for the player in a decoupled, signal-driven way.
# SRP: Only manages camera tracking and smoothing.

extends Node2D

# Signal emitted when the camera position changes
# Used by systems like VisualBackgroundSystem for parallax effects
signal camera_moved(camera_position: Vector2, camera_zoom: Vector2)

@onready var camera: Camera2D = $Camera2D

var _player: Node2D = null
var _previous_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Connect to the global player_spawned signal
	if GlobalSignals.player_spawned.is_connected(_on_player_spawned):
		GlobalSignals.player_spawned.disconnect(_on_player_spawned)
	GlobalSignals.player_spawned.connect(_on_player_spawned)
	# Optionally, disable camera until player is spawned
	camera.enabled = false

func _on_player_spawned(player_node: Node2D) -> void:
	_player = player_node
	camera.enabled = true
	camera.make_current()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0 # Adjust for desired smoothness
	
	# Position the camera to ensure ground is at bottom of viewport
	_adjust_initial_camera_position()

func _process(delta: float) -> void:
	if _player and camera.enabled:
		var target_position = _player.global_position
		
		# Get the viewport size
		var viewport_size = get_viewport().get_visible_rect().size
		
		# Position the camera so that ground level (y=0) is at 80% of the viewport height from the top
		# This leaves 20% of the viewport below the ground level for visual padding
		var ground_viewport_position = viewport_size.y * 0.8
		
		# Calculate the camera y position that places ground level at the desired viewport position
		var camera_y_position = -(viewport_size.y / 2) + ground_viewport_position
		
		# If player is above a certain height, follow them vertically
		# Otherwise, keep the ground at the desired position in the viewport
		if _player.global_position.y < camera_y_position - viewport_size.y * 0.3:
			# Player is high enough, follow them vertically
			target_position.y = _player.global_position.y
		else:
			# Keep ground at desired position in viewport
			target_position.y = camera_y_position
		
		# Set camera position
		camera.position = target_position
		
		# Emit signal if camera position has changed
		if camera.position != _previous_position:
			camera_moved.emit(camera.position, camera.zoom)
			_previous_position = camera.position

# Returns the current camera position for systems that need it
# Used as a fallback when signal-based updates are disabled
func get_camera_position() -> Vector2:
	return camera.position if camera else Vector2.ZERO

# Adjusts the initial camera position to ensure ground level (y=0) is at an appropriate height in the viewport
func _adjust_initial_camera_position() -> void:
	if not _player:
		return
		
	# Get the viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Position the camera so that ground level (y=0) is at 80% of the viewport height from the top
	# This leaves 20% of the viewport below the ground level for visual padding
	var ground_viewport_position = viewport_size.y * 0.8
	
	# Calculate the camera y position that places ground level at the desired viewport position
	var camera_y_position = -(viewport_size.y / 2) + ground_viewport_position
	
	# Set the camera position
	camera.position.x = _player.global_position.x
	camera.position.y = camera_y_position
	
	# Update previous position to avoid unnecessary signal emission
	_previous_position = camera.position
	
	# Emit signal for initial camera position
	camera_moved.emit(camera.position, camera.zoom)
	
	print("[CameraManager] Adjusted initial camera position to: ", camera.position, 
		" (ground at viewport position: ", ground_viewport_position, ")")

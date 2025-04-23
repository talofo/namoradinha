class_name CameraSystem
extends Node2D

signal camera_moved(camera_position: Vector2, camera_zoom: Vector2)

@onready var camera: Camera2D = $Camera2D

var _config: CameraConfig
var _follow_system: FollowSystem
var _previous_position: Vector2
var _is_initialized: bool = false

func _ready() -> void:
    if not _is_initialized:
        initialize_system()
        
    # Connect to global signals
    if GlobalSignals.player_spawned.is_connected(_on_player_spawned):
        GlobalSignals.player_spawned.disconnect(_on_player_spawned)
    GlobalSignals.player_spawned.connect(_on_player_spawned)

func initialize_system() -> void:
    _config = CameraConfig.new()
    _follow_system = FollowSystem.new(camera, _config)
    _follow_system.initialize()
    _previous_position = Vector2.ZERO
    _is_initialized = true
    print("[CameraSystem] Initialized successfully")

func _process(delta: float) -> void:
    if not _is_initialized:
        return
        
    _follow_system.update(delta)
    
    if camera.position != _previous_position:
        camera_moved.emit(camera.position, camera.zoom)
        _previous_position = camera.position

func _on_player_spawned(player_node: Node2D) -> void:
    _follow_system.set_target(player_node)

func get_camera_position() -> Vector2:
    return camera.position if camera else Vector2.ZERO 
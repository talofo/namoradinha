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
    _camera.position_smoothing_enabled = true
    _camera.position_smoothing_speed = _config.smoothing_speed
    _camera.enabled = false

func update(_delta: float) -> void:
    if not _target or not _camera.enabled:
        return
        
    var target_position = calculate_target_position()
    _camera.position = target_position

func set_target(target: Node2D) -> void:
    _target = target
    if _target:
        _camera.enabled = true
        _camera.make_current()
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
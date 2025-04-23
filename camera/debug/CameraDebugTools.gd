class_name CameraDebugTools
extends Node

var camera_system: CameraSystem
var _camera_enabled: bool = true
var _original_position: Vector2

func _ready() -> void:
    camera_system = get_node_or_null("../")
    if camera_system:
        print("[CameraDebug] Found CameraSystem")
        _original_position = camera_system.camera.position

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_C:
            _camera_enabled = not _camera_enabled
            if camera_system and camera_system.camera:
                if _camera_enabled:
                    # Re-enable normal camera following
                    camera_system.camera.enabled = true
                    camera_system._is_initialized = true
                else:
                    # Freeze camera at current position
                    _original_position = camera_system.camera.position
                    camera_system._is_initialized = false
                print("[CameraDebug] Camera movement %s" % ("enabled" if _camera_enabled else "frozen")) 
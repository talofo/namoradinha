class_name CameraDebugTools
extends Node

var camera_system: CameraSystem
var _camera_enabled: bool = true

func _ready() -> void:
    camera_system = get_node_or_null("../")
    if camera_system:
        print("[CameraDebug] Found CameraSystem")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_C:
            _camera_enabled = not _camera_enabled
            if camera_system and camera_system.camera:
                camera_system.camera.enabled = _camera_enabled
                print("[CameraDebug] Camera system %s" % ("enabled" if _camera_enabled else "disabled")) 
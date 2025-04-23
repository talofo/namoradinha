class_name BackgroundDebugTools
extends Node

var visual_background_system: VisualBackgroundSystem
var _background_enabled: bool = true
var _original_scroll: Vector2

func _ready() -> void:
    visual_background_system = get_node_or_null("../")
    if visual_background_system:
        print("[BackgroundDebug] Found VisualBackgroundSystem")
        if visual_background_system.parallax_controller:
            _original_scroll = visual_background_system.parallax_controller.scroll_offset

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_B:
            _background_enabled = not _background_enabled
            if visual_background_system and visual_background_system.parallax_controller:
                if _background_enabled:
                    # Re-enable background movement
                    visual_background_system.use_camera_signal = true
                    visual_background_system.parallax_controller.scroll_offset = _original_scroll
                else:
                    # Freeze background at current position
                    _original_scroll = visual_background_system.parallax_controller.scroll_offset
                    visual_background_system.use_camera_signal = false
                print("[BackgroundDebug] Background movement %s" % ("enabled" if _background_enabled else "frozen")) 
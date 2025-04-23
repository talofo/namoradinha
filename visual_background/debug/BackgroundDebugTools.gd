class_name BackgroundDebugTools
extends Node

var visual_background_system: VisualBackgroundSystem
var _background_enabled: bool = true

func _ready() -> void:
    visual_background_system = get_node_or_null("../")
    if visual_background_system:
        print("[BackgroundDebug] Found VisualBackgroundSystem")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_B:
            _background_enabled = not _background_enabled
            if visual_background_system:
                visual_background_system.process_mode = Node.PROCESS_MODE_DISABLED if not _background_enabled else Node.PROCESS_MODE_INHERIT
                print("[BackgroundDebug] Background system %s" % ("enabled" if _background_enabled else "disabled")) 
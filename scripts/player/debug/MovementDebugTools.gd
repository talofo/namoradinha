class_name MovementDebugTools
extends Node

var camera_system: CameraSystem
var visual_background_system: VisualBackgroundSystem

# Debug state tracking
var _background_enabled: bool = true
var _camera_enabled: bool = true

# Debug UI
var status_label: Label

func _ready() -> void:
    # Find systems
    var game_node = get_node("/root/Game")
    camera_system = game_node.get_node_or_null("CameraSystem")
    var environment_system = game_node.get_node_or_null("EnvironmentSystem")
    if environment_system:
        visual_background_system = environment_system.get_node_or_null("VisualBackgroundSystem")
    
    # Create UI elements
    _create_status_label()
    _update_status_display()

func _create_status_label() -> void:
    # Create CanvasLayer
    var canvas_layer = CanvasLayer.new()
    canvas_layer.layer = 100
    add_child(canvas_layer)
    
    # Create StatusLabel
    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    status_label.size = Vector2(200, 60)
    
    # Center the label at the top of the screen
    var viewport_size = get_viewport().get_visible_rect().size
    status_label.position = Vector2(
        (viewport_size.x - status_label.size.x) / 2,  # Center horizontally
        10  # 10 pixels from top
    )
    
    canvas_layer.add_child(status_label)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_B:
                _toggle_background()
            KEY_C:
                _toggle_camera()

func _toggle_background() -> void:
    _background_enabled = not _background_enabled
    if visual_background_system:
        visual_background_system.process_mode = Node.PROCESS_MODE_DISABLED if not _background_enabled else Node.PROCESS_MODE_INHERIT
    _update_status_display()

func _toggle_camera() -> void:
    _camera_enabled = not _camera_enabled
    if camera_system and camera_system.camera:
        camera_system.camera.enabled = _camera_enabled
    _update_status_display()

func _update_status_display() -> void:
    if status_label:
        status_label.text = """Movement Debug:
Background: %s (B)
Camera: %s (C)""" % [
            "ON" if _background_enabled else "OFF",
            "ON" if _camera_enabled else "OFF"
        ] 
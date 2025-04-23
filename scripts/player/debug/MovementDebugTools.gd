class_name MovementDebugTools
extends Node

var camera_system: CameraSystem
var visual_background_system: VisualBackgroundSystem

# Debug state tracking
var _background_enabled: bool = true
var _camera_enabled: bool = true
var _debug_enabled: bool = true

# Debug UI
var status_label: Label
var _debug_draw: Node2D

# Position tracking
var _previous_player_pos: Vector2
var _previous_camera_pos: Vector2

func _ready() -> void:
    # Find systems
    var game_node = get_node("/root/Game")
    camera_system = game_node.get_node_or_null("CameraSystem")
    var environment_system = game_node.get_node_or_null("EnvironmentSystem")
    if environment_system:
        visual_background_system = environment_system.get_node_or_null("VisualBackgroundSystem")
    
    # Create UI elements
    _create_status_label()
    _create_debug_visuals()
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

func _create_debug_visuals() -> void:
    _debug_draw = Node2D.new()
    add_child(_debug_draw)
    _debug_draw.draw.connect(_on_debug_draw)

func _on_debug_draw() -> void:
    if camera_system and camera_system.camera:
        # Draw camera bounds
        var cam_pos = camera_system.camera.global_position
        var viewport_size = get_viewport().get_visible_rect().size
        _debug_draw.draw_rect(Rect2(cam_pos - viewport_size/2, viewport_size), Color.RED, false)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_B:
                _toggle_background()
            KEY_C:
                _toggle_camera()
            KEY_D:
                _debug_enabled = not _debug_enabled
                _update_status_display()

func _toggle_background() -> void:
    _background_enabled = not _background_enabled
    if visual_background_system and visual_background_system.parallax_controller:
        if _background_enabled:
            visual_background_system.use_camera_signal = true
        else:
            visual_background_system.use_camera_signal = false
    _update_status_display()

func _toggle_camera() -> void:
    _camera_enabled = not _camera_enabled
    if camera_system and camera_system.camera:
        if _camera_enabled:
            camera_system.camera.enabled = true
            camera_system._is_initialized = true
        else:
            camera_system._is_initialized = false
    _update_status_display()

func _physics_process(delta: float) -> void:
    if not _debug_enabled:
        return
        
    var player = get_node_or_null("/root/Game/PlayerCharacter")
    if player:
        var current_pos = player.global_position
        if _previous_player_pos != Vector2.ZERO:
            var movement = current_pos - _previous_player_pos
            print("[MovementDebug] Player movement: ", movement)
        _previous_player_pos = current_pos
        
    if camera_system and camera_system.camera:
        var current_pos = camera_system.camera.global_position
        if _previous_camera_pos != Vector2.ZERO:
            var movement = current_pos - _previous_camera_pos
            print("[MovementDebug] Camera movement: ", movement)
        _previous_camera_pos = current_pos

func _update_status_display() -> void:
    if status_label:
        status_label.text = """Movement Debug:
Background Movement: %s (B)
Camera Movement: %s (C)
Debug Visuals: %s (D)""" % [
            "ACTIVE" if _background_enabled else "FROZEN",
            "ACTIVE" if _camera_enabled else "FROZEN",
            "ON" if _debug_enabled else "OFF"
        ] 
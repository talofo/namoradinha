class_name GroundVisualManager
extends Node2D

# Both EnvironmentTheme and TransitionHelper are available globally via class_name

signal transition_completed
signal fallback_activated(reason)

# Configuration
@export var transition_duration: float = 0.5

# Internal state
var current_sprite: CanvasItem = null
var active_tween: Tween = null
var current_theme_id: String = ""
var _debug_enabled: bool = false

func _ready():
	# Ensure sprite container exists
	if get_child_count() == 0:
		add_child(Node2D.new())

func apply_theme(theme: EnvironmentTheme) -> void:
	if not theme:
		push_error("GroundVisualManager: Null theme provided")
		_create_fallback_ground() # Create fallback even if theme is null
		fallback_activated.emit("Null theme provided")
		return
	
	current_theme_id = theme.theme_id
	
	if not theme.ground_texture:
		# Instead of just warning, create a placeholder texture
		var placeholder_texture = _create_placeholder_texture(Color(0.5, 0.3, 0.1, 1.0))  # Brown color for ground
		_apply_ground_texture(placeholder_texture, theme.ground_tint)
		# Use print instead of warning for less severe notification
		if _debug_enabled:
			print("GroundVisualManager: Ground texture missing in theme: " + theme.theme_id + " (using placeholder)")
		return
	
	# Apply the texture, with transition if needed
	_apply_ground_texture(theme.ground_texture, theme.ground_tint)

func apply_ground_visuals(ground_data: Array) -> void:
	# Clear existing visuals
	if current_sprite:
		current_sprite.queue_free()
		current_sprite = null
	
	# Create container for all ground visuals
	var container = Node2D.new()
	add_child(container)
	
	# Get the current theme
	var theme = null
	if get_parent() and get_parent().has_method("get_theme_by_id"):
		theme = get_parent().get_theme_by_id(current_theme_id)
	
	if not theme or not theme.ground_texture:
		_create_fallback_ground()
		fallback_activated.emit("Cannot apply ground visuals - missing theme or texture")
		return
	
	# Create sprites for each ground segment
	for data in ground_data:
		var sprite = Sprite2D.new()
		sprite.texture = theme.ground_texture
		sprite.position = data.position
		sprite.scale = data.size / sprite.texture.get_size()
		sprite.modulate = theme.ground_tint
		container.add_child(sprite)
	
	current_sprite = container
	transition_completed.emit()

func _apply_ground_texture(texture: Texture2D, tint: Color = Color.WHITE) -> void:
	# If we already have a sprite, transition to the new texture
	if current_sprite:
		_transition_to_new_texture(texture, tint)
	else:
		# Create new ground sprite
		_create_ground_sprite(texture, tint)

func _create_ground_sprite(texture: Texture2D, tint: Color = Color.WHITE) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = tint
	
	# Position will be set by apply_ground_visuals, but use a default for now
	sprite.position = Vector2(0, 0)
	
	add_child(sprite)
	current_sprite = sprite
	transition_completed.emit()

func _create_placeholder_texture(color: Color = Color(0.5, 0.3, 0.1, 1.0)) -> Texture2D:
	# Create a simple 64x64 texture with the given color
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	# Add some noise/pattern to make it look less flat
	for x in range(64):
		for y in range(64):
			var noise_value = (x + y) % 8 / 8.0 * 0.2
			var pixel_color = color.lightened(noise_value)
			image.set_pixel(x, y, pixel_color)
	
	return ImageTexture.create_from_image(image)

func _create_fallback_ground() -> void:
	# Create brown debug visual instead of magenta
	var fallback = ColorRect.new()
	fallback.color = Color(0.5, 0.3, 0.1, 0.7)  # Semi-transparent brown
	fallback.size = Vector2(2000, 100)   # Adjust to match ground size
	fallback.position = Vector2(-1000, -50)  # Center it
	
	# Set a very low z-index to ensure it's behind other elements
	fallback.z_index = -100
	
	# Add a label to indicate it's a fallback
	var label = Label.new()
	label.text = "FALLBACK GROUND"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = fallback.size
	fallback.add_child(label)
	
	if current_sprite:
		current_sprite.queue_free()
	
	add_child(fallback)
	current_sprite = fallback
	transition_completed.emit()

func _transition_to_new_texture(new_texture: Texture2D, new_tint: Color = Color.WHITE) -> void:
	# Cancel any active tweens
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	
	# Create new sprite with same position/transform
	var new_sprite = Sprite2D.new()
	new_sprite.texture = new_texture
	new_sprite.modulate = new_tint
	new_sprite.modulate.a = 0.0  # Start transparent
	new_sprite.position = current_sprite.position
	new_sprite.scale = current_sprite.scale
	add_child(new_sprite)
	
	# Use transition helper for fade effect
	var old_sprite = current_sprite
	current_sprite = new_sprite
	
	active_tween = TransitionHelper.fade_transition(
		old_sprite, 
		new_sprite, 
		transition_duration,
		func():
			old_sprite.queue_free()
			transition_completed.emit()
	)

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
	_debug_enabled = enabled

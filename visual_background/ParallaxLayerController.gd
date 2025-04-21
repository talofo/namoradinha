class_name ParallaxLayerController
extends ParallaxBackground

# Configuration
@export var performance_monitoring: bool = true
@export var recommended_layer_count: int = 7  # Performance guideline from brief, NOT a hard limit
@export var debug_mode: bool = false

# Performance tracking
var texture_memory_usage: float = 0  # Estimate in MB
var active_layer_count: int = 0
var draw_call_estimate: int = 0

# Internal tracking
var active_layers = {}  # Dictionary to track created layers by name

func build_layers(layer_configs: Array):
	# Reset performance counters
	texture_memory_usage = 0
	active_layer_count = 0
	draw_call_estimate = 0
	
	# Process each layer config
	for config in layer_configs:
		# Skip if invalid config
		if not config:
			continue
			
		# Create parallax layer
		var parallax_layer = ParallaxLayer.new()
		parallax_layer.motion_scale = config.parallax_ratio
		parallax_layer.z_index = config.z_index
		parallax_layer.name = "Layer_" + str(config.layer_name)
		
		# Process each element in the layer
		for element in config.elements:
			# Skip if invalid element
			if not element or not element.texture:
				continue
				
			# Create sprite for this element
			var sprite = Sprite2D.new()
			sprite.texture = element.texture
			sprite.position = element.offset
			sprite.scale = element.scale
			sprite.modulate = element.modulate
			sprite.z_index = element.z_index
			
			# Track approximate texture memory (very rough estimate)
			if element.texture:
				var tex_size = element.texture.get_width() * element.texture.get_height() * 4  # 4 bytes per pixel (RGBA)
				texture_memory_usage += tex_size / (1024 * 1024)  # Convert to MB
			
			# Estimate draw calls (very rough)
			draw_call_estimate += 1
			
			# Handle tiling mode
			match element.tiling_mode:
				0:  # None
					sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
				1:  # Horizontal
					sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
					# Setup horizontal tiling (depends on your implementation)
					var viewport_size = get_viewport().get_visible_rect().size
					sprite.region_enabled = true
					sprite.region_rect = Rect2(0, 0, viewport_size.x * 2, element.texture.get_height())
				2:  # Vertical
					sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
					# Setup vertical tiling (depends on your implementation)
					var viewport_size = get_viewport().get_visible_rect().size
					sprite.region_enabled = true
					sprite.region_rect = Rect2(0, 0, element.texture.get_width(), viewport_size.y * 2)
				3:  # Both
					sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
					# Setup tiling in both directions
					var viewport_size = get_viewport().get_visible_rect().size
					sprite.region_enabled = true
					sprite.region_rect = Rect2(0, 0, viewport_size.x * 2, viewport_size.y * 2)
			
			# Apply any region settings
			if element.region_enabled:
				sprite.region_enabled = true
				sprite.region_rect = element.region_rect
			
			# Add sprite to layer
			parallax_layer.add_child(sprite)
		
		# Add the layer to the parallax background
		add_child(parallax_layer)
		active_layer_count += 1
		
		# Track this layer
		active_layers[config.layer_name] = parallax_layer
		
	# Performance monitoring (if enabled)
	if performance_monitoring:
		# Check against performance guidelines
		if active_layer_count > recommended_layer_count:
			push_warning("Performance Warning: Using %d active layers (recommended: %d)" % [active_layer_count, recommended_layer_count])
		
		if texture_memory_usage > 12.0:  # 12MB guideline from brief
			push_warning("Performance Warning: Estimated texture memory usage is %.2f MB (recommended: 12 MB)" % texture_memory_usage)
			
		if draw_call_estimate > 15:  # 15 draw calls guideline from brief
			push_warning("Performance Warning: Estimated draw calls per frame: %d (recommended: 15)" % draw_call_estimate)
		
		if debug_mode:
			print("Background System Stats - Layers: %d, Memory: %.2f MB, Draw Calls: %d" % 
				[active_layer_count, texture_memory_usage, draw_call_estimate])

func clear_layers():
	# Remove all existing parallax layers
	for child in get_children():
		if child is ParallaxLayer:
			child.queue_free()
	
	# Clear our tracking dictionary
	active_layers.clear()
	
	# Reset counters
	active_layer_count = 0
	texture_memory_usage = 0
	draw_call_estimate = 0

func update_scroll(camera_position: Vector2):
	# Update the scroll offset based on camera position
	# ParallaxBackground handles the differential scrolling automatically
	scroll_offset = camera_position

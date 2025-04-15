extends Node

# This script creates a global overlay that shows where rocks are supposed to be
# It's a last resort approach to debug rock visibility issues

var overlay_canvas: CanvasLayer
var debug_container: Control
var rock_positions = []
var active = true

func _ready():
	print("GlobalRockDebugOverlay: Initializing")
	
	# Create the overlay
	create_overlay()
	
	# Connect to signals
	get_tree().node_added.connect(_on_node_added)
	
	# Schedule periodic updates
	_schedule_update()

func create_overlay():
	# Create a canvas layer that will be on top of everything
	overlay_canvas = CanvasLayer.new()
	overlay_canvas.layer = 128  # Very high layer number
	add_child(overlay_canvas)
	
	# Create a container for debug elements
	debug_container = Control.new()
	debug_container.name = "RockDebugContainer"
	debug_container.anchor_right = 1.0
	debug_container.anchor_bottom = 1.0
	overlay_canvas.add_child(debug_container)
	
	# Add a title label
	var title = Label.new()
	title.text = "ROCK DEBUG OVERLAY"
	title.position = Vector2(10, 10)
	title.modulate = Color(1, 0, 0)
	debug_container.add_child(title)
	
	# Add a toggle button
	var toggle_button = Button.new()
	toggle_button.text = "Toggle Overlay"
	toggle_button.position = Vector2(10, 40)
	toggle_button.pressed.connect(_toggle_overlay)
	debug_container.add_child(toggle_button)
	
	print("GlobalRockDebugOverlay: Overlay created")

func _on_node_added(node):
	# Check if the node is a rock obstacle
	if node is RockObstacle:
		print("GlobalRockDebugOverlay: Rock detected at " + str(node.position))
		
		# Wait until the node is ready
		if not node.is_inside_tree():
			await node.ready
		
		# Add to our list of rock positions
		rock_positions.append(node.global_position)
		
		# Update the overlay
		update_overlay()

func update_overlay():
	if not active:
		return
		
	# Clear previous markers
	for child in debug_container.get_children():
		if child.name.begins_with("RockMarker"):
			child.queue_free()
	
	# Add markers for each rock position
	for i in range(rock_positions.size()):
		var pos = rock_positions[i]
		
		# Create a marker
		var marker = ColorRect.new()
		marker.name = "RockMarker" + str(i)
		marker.size = Vector2(30, 30)
		marker.position = Vector2(pos.x, pos.y) - marker.size / 2
		marker.color = Color(1, 0, 0, 0.5)  # Semi-transparent red
		debug_container.add_child(marker)
		
		# Add a label
		var label = Label.new()
		label.text = "Rock " + str(i) + "\nPos: " + str(pos)
		label.position = Vector2(pos.x + 20, pos.y)
		label.name = "RockLabel" + str(i)
		label.modulate = Color(1, 1, 0)  # Yellow
		debug_container.add_child(label)
	
	# Add a count label
	var count_label = Label.new()
	count_label.name = "RockMarkerCount"
	count_label.text = "Total Rocks: " + str(rock_positions.size())
	count_label.position = Vector2(10, 70)
	count_label.modulate = Color(1, 1, 0)  # Yellow
	debug_container.add_child(count_label)
	
	print("GlobalRockDebugOverlay: Updated overlay with " + str(rock_positions.size()) + " rocks")

func _toggle_overlay():
	active = !active
	debug_container.visible = active
	print("GlobalRockDebugOverlay: Overlay toggled to " + str(active))

func _schedule_update():
	# Schedule a periodic update
	await get_tree().create_timer(2.0).timeout
	
	# Find all rocks in the scene
	var rocks = get_tree().get_nodes_in_group("obstacles")
	print("GlobalRockDebugOverlay: Found " + str(rocks.size()) + " obstacles in the scene")
	
	# Update positions
	rock_positions.clear()
	for rock in rocks:
		if rock is RockObstacle:
			rock_positions.append(rock.global_position)
			print("GlobalRockDebugOverlay: Rock at " + str(rock.global_position) + " with z-index " + str(rock.z_index))
	
	# Update the overlay
	update_overlay()
	
	# Schedule the next update
	_schedule_update()

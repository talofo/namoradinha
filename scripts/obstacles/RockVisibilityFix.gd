extends Node

# This script is a global autoload that ensures rock obstacles are always visible
# by setting their z-index higher than other elements

const ROCK_Z_INDEX = 1000  # Very high z-index to ensure rocks are on top of everything

func _ready():
	print("RockVisibilityFix: Initializing")
	print("RockVisibilityFix: DEBUG - This script should make rocks visible with z-index %d" % ROCK_Z_INDEX)
	
	# Connect to the node added signal to catch when rocks are added to the scene
	get_tree().node_added.connect(_on_node_added)
	
	# Process existing rocks in the scene
	_process_existing_rocks()
	
	# Schedule a delayed check to see if any rocks were found
	get_tree().create_timer(2.0).timeout.connect(_delayed_check)

func _delayed_check():
	var rocks = get_tree().get_nodes_in_group("obstacles")
	print("RockVisibilityFix: DEBUG - Found %d obstacles in the scene after 2 seconds" % rocks.size())
	
	for rock in rocks:
		if rock is RockObstacle:
			print("RockVisibilityFix: DEBUG - Rock found at position %s with z-index %d" % [str(rock.position), rock.z_index])

func _process_existing_rocks():
	# Find all existing rock obstacles in the scene
	var rocks = get_tree().get_nodes_in_group("obstacles")
	
	print("RockVisibilityFix: DEBUG - Found %d obstacles in the scene during initialization" % rocks.size())
	
	for rock in rocks:
		if rock is RockObstacle:
			print("RockVisibilityFix: DEBUG - Processing existing rock at position %s" % str(rock.position))
			_apply_visibility_fix(rock)
		else:
			print("RockVisibilityFix: DEBUG - Found non-RockObstacle in obstacles group: %s" % rock.get_class())

func _on_node_added(node):
	# Check if the added node is a rock obstacle
	if node is RockObstacle:
		print("RockVisibilityFix: DEBUG - Rock obstacle added to scene at position %s" % str(node.position))
		
		# Wait until the node is ready
		if not node.is_inside_tree():
			print("RockVisibilityFix: DEBUG - Waiting for rock to be ready...")
			await node.ready
			print("RockVisibilityFix: DEBUG - Rock is now ready")
		
		_apply_visibility_fix(node)
	elif "Rock" in node.get_class():
		print("RockVisibilityFix: DEBUG - Node with 'Rock' in class name added but not a RockObstacle: %s" % node.get_class())

func _apply_visibility_fix(rock):
	print("RockVisibilityFix: Applying visibility fix to rock at position %s" % str(rock.position))
	
	# Set a very high z-index to ensure the rock is visible above everything
	rock.z_index = ROCK_Z_INDEX
	
	# Make sure the sprite is visible
	var sprite = rock.get_node_or_null("Sprite2D")
	if sprite:
		sprite.visible = true
		
		# Ensure the sprite has a texture
		if not sprite.texture:
			# Force recreation of the visual representation
			rock._create_visual_representation()
		
		# Make the sprite larger for better visibility
		sprite.scale = Vector2(1.5, 1.5)
	
	# Add a debug outline to make it more visible
	var outline = rock.get_node_or_null("DebugOutline")
	if not outline:
		outline = ColorRect.new()
		outline.name = "DebugOutline"
		outline.size = Vector2(100, 100)  # Larger outline
		outline.position = Vector2(-50, -50)
		outline.color = Color(1.0, 1.0, 0.0, 0.5)  # Semi-transparent yellow for better contrast
		outline.z_index = -1  # Place behind the sprite
		rock.add_child(outline)
	
	# Add a label above the rock for debugging
	var label = rock.get_node_or_null("DebugLabel")
	if not label:
		label = Label.new()
		label.name = "DebugLabel"
		label.text = "ROCK"
		label.position = Vector2(-25, -80)
		label.modulate = Color(1.0, 1.0, 0.0)  # Yellow text
		rock.add_child(label)
	
	print("RockVisibilityFix: Rock at position %s now has z-index %d" % [str(rock.position), rock.z_index])

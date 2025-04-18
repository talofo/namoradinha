class_name IContentDistributionStrategy
extends RefCounted

# Import required classes
# In Godot 4.4+, classes with class_name are globally available

# Virtual method to distribute content within a chunk
# Parameters:
# - chunk_definition: The chunk to distribute content in
# - flow_state: Current flow state from FlowAndDifficultyController
# - difficulty: Current difficulty setting (e.g., "low", "medium", "hard")
# - content_rules: ContentDistribution resource with rules for placement
# - current_placements_history: Array of previous placements for context
# Returns: Array of placement dictionaries with structure:
# [
#   {
#     "category": "obstacles",
#     "type": "Log",
#     "position": Vector3(10, 0, 5)
#   },
#   ...
# ]
func distribute_content(
	_chunk_definition: ChunkDefinition, 
	_flow_state: FlowAndDifficultyController.FlowState, 
	_difficulty: String, 
	_content_rules: ContentDistribution, 
	_current_placements_history: Array
) -> Array:
	push_error("IContentDistributionStrategy.distribute_content: Method not implemented")
	return []

# Debug flag
var _debug_enabled: bool = true

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
	_debug_enabled = enabled

# Helper method to validate a potential placement against constraints
# Parameters:
# - position: The proposed position for the content (can be Vector3 or Vector2)
# - content_category: The category of content (e.g., "obstacles", "boosts")
# - content_type: The specific type within the category (e.g., "Log", "SpeedPad")
# - existing_placements: Array of existing placements to check against
# - constraints: Dictionary of placement constraints from ContentDistribution
# Returns: true if placement is valid, false otherwise
func validate_placement(
	position, 
	content_category: String, 
	content_type: String, 
	existing_placements: Array, 
	constraints: Dictionary
) -> bool:
	# Debug print
	if _debug_enabled:
		print("DEBUG: Validating placement for %s/%s at position %s" % [content_category, content_type, str(position)])
		print("DEBUG: Number of existing placements: %d" % existing_placements.size())
	# Extract coordinates from position based on its type
	var width_offset: float
	var height: float
	var distance_along_chunk: float
	
	if position is Vector3:
		width_offset = position.x
		height = position.y
		distance_along_chunk = position.z
	elif position is Vector2:
		width_offset = position.x
		height = 0
		distance_along_chunk = position.y
	else:
		push_error("IContentDistributionStrategy.validate_placement: Unsupported position type")
		return false
	
	# Check minimum spacing between same category
	# Get singular form of category name for constraint lookup
	var singular_category = content_category
	if content_category == "obstacles":
		singular_category = "obstacle"
	elif content_category == "collectibles":
		singular_category = "collectible"
	elif content_category == "boosts":
		singular_category = "boost"
	
	# Check both plural and singular forms in constraints
	var min_distance = 0.0
	if constraints.has("minimum_spacing"):
		if constraints["minimum_spacing"].has(content_category):
			min_distance = constraints["minimum_spacing"][content_category]["distance"]
		elif constraints["minimum_spacing"].has(singular_category):
			min_distance = constraints["minimum_spacing"][singular_category]["distance"]
		
		if min_distance > 0.0:
			for placement in existing_placements:
				if placement["category"] == content_category:
					# Calculate 3D distance manually
					var dx = width_offset - placement["width_offset"]
					var dy = height - placement["height"]
					var dz = distance_along_chunk - placement["distance_along_chunk"]
					var distance = sqrt(dx*dx + dy*dy + dz*dz)
					
					if distance < min_distance:
						if _debug_enabled:
							print("DEBUG: Placement validation failed for %s/%s: Too close to another %s (distance: %f, min required: %f)" % 
								[content_category, content_type, content_category, distance, min_distance])
						return false
	
	# Check global minimum spacing between any content
	if constraints.has("minimum_spacing") and constraints["minimum_spacing"].has("any_content"):
		var global_min_distance = constraints["minimum_spacing"]["any_content"]["distance"]
		for placement in existing_placements:
			# Calculate 3D distance manually
			var dx = width_offset - placement["width_offset"]
			var dy = height - placement["height"]
			var dz = distance_along_chunk - placement["distance_along_chunk"]
			var distance = sqrt(dx*dx + dy*dy + dz*dz)
			
			if distance < global_min_distance:
				if _debug_enabled:
					print("DEBUG: Placement validation failed for %s/%s: Too close to another content (distance: %f, min required: %f)" % 
						[content_category, content_type, distance, global_min_distance])
				return false
	
	# Check max per chunk (this would typically be checked before calling validate_placement)
	# but we include it here for completeness
	if constraints.has("max_per_chunk") and constraints["max_per_chunk"].has(content_category):
		var max_count = constraints["max_per_chunk"][content_category]
		var current_count = 0
		for placement in existing_placements:
			if placement["category"] == content_category:
				current_count += 1
		if current_count >= max_count:
			if _debug_enabled:
				print("DEBUG: Placement validation failed for %s/%s: Max count reached (%d/%d)" % 
					[content_category, content_type, current_count, max_count])
			return false
	
	# All checks passed
	if _debug_enabled:
		print("DEBUG: Placement validation result for %s/%s: VALID" % [content_category, content_type])
	return true

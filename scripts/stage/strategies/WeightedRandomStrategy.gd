class_name WeightedRandomStrategy
extends "res://scripts/stage/strategies/IContentDistributionStrategy.gd"

# Random number generator for consistent randomization
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
# Store used positions to prevent duplicates
var _used_positions = []

func _init():
	_rng.randomize()

# Note: _debug_enabled and set_debug_enabled are inherited from parent class IContentDistributionStrategy
# We don't need to redeclare them here

# Implementation of the distribute_content method from IContentDistributionStrategy
func distribute_content(
	chunk_definition: ChunkDefinition, 
	flow_state: FlowAndDifficultyController.FlowState, 
	difficulty: String, 
	content_rules: ContentDistribution, 
	current_placements_history: Array
) -> Array:
	if _debug_enabled:
		print("WeightedRandomStrategy: Distributing content for chunk '%s' with flow state %s and difficulty %s" % 
			  [chunk_definition.chunk_id, FlowAndDifficultyController.FlowState.keys()[flow_state], difficulty])
	
	# Clear used positions for this new distribution
	_used_positions.clear()
	
	# Initialize result array
	var placements = []
	
	# Get content categories and apply difficulty scaling
	var categories = _get_scaled_categories(content_rules, flow_state, difficulty)
	
	# Get placement constraints with difficulty scaling applied
	var constraints = _get_scaled_constraints(content_rules, flow_state, difficulty)
	
	# Determine target counts for each category based on weights
	var target_counts = _calculate_target_counts(categories, constraints, chunk_definition.length)
	
	if _debug_enabled:
		print("DEBUG: Categories after scaling: %s" % categories)
		print("DEBUG: Target counts: %s" % target_counts)
	
	# Process each category
	for category_name in categories.keys():
		var category = categories[category_name]
		var target_count = target_counts[category_name]
		
		if _debug_enabled:
			print("WeightedRandomStrategy: Placing %d items of category '%s'" % [target_count, category_name])
		
		# Get allowed entities for this category
		var allowed_entities = category["allowed_entities"]
		if allowed_entities.is_empty():
			if _debug_enabled:
				print("WeightedRandomStrategy: No allowed entities for category '%s', skipping" % category_name)
			continue
		
		# Get preferred marker tag for this category
		var placement_tag = category["placement_tag"]
		
		# Find suitable markers in the chunk
		var suitable_markers = _find_suitable_markers(chunk_definition, category_name, placement_tag, content_rules)
		
		# Place items
		for i in range(target_count):
			# Select a random entity from allowed entities
			var entity_index = _rng.randi() % allowed_entities.size()
			var content_type = allowed_entities[entity_index]
			
			# Try to place at a marker first
			var position = Vector3.ZERO
			var placed = false
			
			if not suitable_markers.is_empty():
				# Shuffle markers to avoid predictable patterns
				suitable_markers.shuffle()
				
				# Try each marker
				for marker in suitable_markers:
					# Convert Vector2 position to Vector3
					var marker_pos = marker["position"]
					if marker_pos is Vector2:
						position = Vector3(marker_pos.x, 0, marker_pos.y)
					else:
						position = marker_pos
					
					# Validate placement
					if validate_placement(position, category_name, content_type, placements, constraints):
						# Add to placements with explicit coordinate naming
						placements.append({
							"category": category_name,
							"type": content_type,
							"distance_along_chunk": position.z,
							"height": position.y,
							"width_offset": position.x
						})
						
						# Store this position to avoid duplicates
						_used_positions.append(position)
						
						placed = true
						break
			
			# If no suitable marker found, generate a procedural position
			if not placed:
				# For obstacles (rocks), only place them in ground chunks
				if category_name == "obstacles":
					# Check if this is a ground chunk by looking at the chunk_id or checking for ground markers
					var is_ground_chunk = false
					
					# Check if the chunk ID contains "ground"
					if "ground" in chunk_definition.chunk_id.to_lower():
						is_ground_chunk = true
					else:
						# Check if the chunk has any ground markers
						for marker in chunk_definition.layout_markers:
							if marker.has("height_zone") and marker["height_zone"] == "ground":
								is_ground_chunk = true
								break
					
					if not is_ground_chunk:
						if _debug_enabled:
							print("WeightedRandomStrategy: Skipping procedural placement for obstacles in non-ground chunk '%s'" % chunk_definition.chunk_id)
						break
					
					# Use sector-based placement for obstacles to ensure they're spread out
					# Divide the available width into sectors based on target count
					var total_width = 4000.0  # -2000 to 2000 = 4000 total width
					var sector_width = total_width / target_count
					var sector_start = -2000.0 + (i * sector_width)
					var sector_end = sector_start + sector_width
					
					if _debug_enabled:
						print("WeightedRandomStrategy: Using sector %d for obstacle: x range [%f, %f]" % [i, sector_start, sector_end])
					
					# Try multiple random positions within this sector
					for attempt in range(15):  # More attempts for obstacles
						# Generate a random position along the chunk length
						var x_offset = 0.0
						var y_value = 0.0  # Always place on ground by default
						var z_offset = 0.0
						
						# For first attempt, use the sector-based approach
						if attempt < 5:
							# Place within the assigned sector
							x_offset = _rng.randf_range(sector_start, sector_end)
							z_offset = _rng.randf_range(0, chunk_definition.length)
						else:
							# For later attempts, expand the range to find any valid position
							var range_expansion = 1.0 + (attempt - 5) * 0.2  # Expand by 20% each attempt
							x_offset = _rng.randf_range(-2000.0 * range_expansion, 2000.0 * range_expansion)
							z_offset = _rng.randf_range(0, chunk_definition.length)
						
						position = Vector3(x_offset, y_value, z_offset)
						
						# Check if this position is too close to any previously used position
						var too_close_to_existing = false
						for used_pos in _used_positions:
							var dx = position.x - used_pos.x
							var dz = position.z - used_pos.z
							var distance = sqrt(dx*dx + dz*dz)
							if distance < 1000.0:  # Increased minimum distance between obstacles from 100 to 1000
								too_close_to_existing = true
								break
						
						if too_close_to_existing:
							if _debug_enabled and attempt == 14:
								print("WeightedRandomStrategy: Position too close to existing position, trying again")
							continue
						
						# Validate placement
						if validate_placement(position, category_name, content_type, placements, constraints):
							# Add to placements with explicit coordinate naming
							placements.append({
								"category": category_name,
								"type": content_type,
								"distance_along_chunk": position.z,
								"height": position.y,
								"width_offset": position.x
							})
							
							# Store this position to avoid duplicates
							_used_positions.append(position)
							
							placed = true
							break
				else:
					# For non-obstacle content, use standard random placement
					# Try multiple random positions
					for attempt in range(10):  # Limit attempts to avoid infinite loops
						# Generate a random position along the chunk length
						var x_offset = 0.0
						var y_value = 0.0  # Always place on ground by default
						
						# Standard range for other content
						x_offset = _rng.randf_range(-30.0, 30.0)
						var z_offset = _rng.randf_range(0, chunk_definition.length)  # Along length
						position = Vector3(x_offset, y_value, z_offset)
						
						# Validate placement
						if validate_placement(position, category_name, content_type, placements, constraints):
							# Add to placements with explicit coordinate naming
							placements.append({
								"category": category_name,
								"type": content_type,
								"distance_along_chunk": position.z,
								"height": position.y,
								"width_offset": position.x
							})
							placed = true
							break
				
				if not placed and _debug_enabled:
					print("WeightedRandomStrategy: Failed to place item of type '%s' in category '%s' after multiple attempts" % 
						  [content_type, category_name])
	
	# Check and fix disallowed patterns
	placements = _check_and_fix_disallowed_patterns(placements, constraints)
	
	if _debug_enabled:
		print("WeightedRandomStrategy: Placed %d items total" % placements.size())
	
	return placements

# Get content categories with difficulty scaling applied
func _get_scaled_categories(content_rules: ContentDistribution, flow_state: FlowAndDifficultyController.FlowState, difficulty: String) -> Dictionary:
	var categories = content_rules.content_categories.duplicate(true)
	var flow_state_name = FlowAndDifficultyController.FlowState.keys()[flow_state]
	
	# Apply flow state scaling
	if content_rules.difficulty_scaling.has("flow_state") and content_rules.difficulty_scaling["flow_state"].has(flow_state_name):
		var flow_scaling = content_rules.difficulty_scaling["flow_state"][flow_state_name]
		
		# Apply density multipliers
		if flow_scaling.has("density_multiplier"):
			for category_name in flow_scaling["density_multiplier"].keys():
				if categories.has(category_name):
					var multiplier = flow_scaling["density_multiplier"][category_name]
					categories[category_name]["base_ratio_weight"] *= multiplier
		
		# Apply allowed entities modifications
		if flow_scaling.has("allowed_entities"):
			for category_name in flow_scaling["allowed_entities"].keys():
				if categories.has(category_name):
					var entity_mods = flow_scaling["allowed_entities"][category_name]
					for entity_mod in entity_mods:
						if entity_mod.begins_with("+"):  # Add entity
							var entity_name = entity_mod.substr(1)
							if not categories[category_name]["allowed_entities"].has(entity_name):
								categories[category_name]["allowed_entities"].append(entity_name)
						elif entity_mod.begins_with("-"):  # Remove entity
							var entity_name = entity_mod.substr(1)
							categories[category_name]["allowed_entities"].erase(entity_name)
	
	# Apply global difficulty scaling
	if content_rules.difficulty_scaling.has("global_difficulty") and content_rules.difficulty_scaling["global_difficulty"].has(difficulty):
		var diff_scaling = content_rules.difficulty_scaling["global_difficulty"][difficulty]
		
		# Apply ratio weights
		if diff_scaling.has("ratio_weights"):
			for category_name in diff_scaling["ratio_weights"].keys():
				if categories.has(category_name):
					categories[category_name]["base_ratio_weight"] = diff_scaling["ratio_weights"][category_name]
	
	return categories

# Get placement constraints with difficulty scaling applied
func _get_scaled_constraints(content_rules: ContentDistribution, flow_state: FlowAndDifficultyController.FlowState, difficulty: String) -> Dictionary:
	var constraints = content_rules.placement_constraints.duplicate(true)
	var flow_state_name = FlowAndDifficultyController.FlowState.keys()[flow_state]
	
	# Apply flow state scaling to constraints
	if content_rules.difficulty_scaling.has("flow_state") and content_rules.difficulty_scaling["flow_state"].has(flow_state_name):
		var flow_scaling = content_rules.difficulty_scaling["flow_state"][flow_state_name]
		
		# Apply max_per_chunk modifications
		if flow_scaling.has("max_per_chunk"):
			for category_name in flow_scaling["max_per_chunk"].keys():
				constraints["max_per_chunk"][category_name] = flow_scaling["max_per_chunk"][category_name]
	
	# Apply global difficulty scaling to constraints
	if content_rules.difficulty_scaling.has("global_difficulty") and content_rules.difficulty_scaling["global_difficulty"].has(difficulty):
		var diff_scaling = content_rules.difficulty_scaling["global_difficulty"][difficulty]
		
		# Apply max_per_chunk modifications
		if diff_scaling.has("max_per_chunk"):
			for category_name in diff_scaling["max_per_chunk"].keys():
				constraints["max_per_chunk"][category_name] = diff_scaling["max_per_chunk"][category_name]
	
	return constraints

# Calculate target counts for each category based on weights and constraints
func _calculate_target_counts(categories: Dictionary, constraints: Dictionary, chunk_length: float) -> Dictionary:
	var target_counts = {}
	var total_weight = 0.0
	
	# Calculate total weight
	for category_name in categories.keys():
		total_weight += categories[category_name]["base_ratio_weight"]
	
	# Base density factor - longer chunks get more content
	var density_factor = chunk_length / 100.0
	
	# Calculate target count for each category
	for category_name in categories.keys():
		var weight_ratio = categories[category_name]["base_ratio_weight"] / total_weight if total_weight > 0 else 0
		var base_count = int(weight_ratio * 10 * density_factor)  # 10 is a base multiplier
		
		# Apply max_per_chunk constraint
		var max_count = constraints["max_per_chunk"].get(category_name, 999)
		target_counts[category_name] = min(base_count, max_count)
	
	return target_counts

	# Find suitable markers in the chunk for a specific category
func _find_suitable_markers(chunk_definition: ChunkDefinition, category_name: String, placement_tag: String, content_rules: ContentDistribution = null) -> Array:
	var suitable_markers = []
	
	# Convert plural category name to singular for matching with markers
	var singular_category_name = category_name
	if category_name == "obstacles":
		singular_category_name = "obstacle"
	elif category_name == "collectibles":
		singular_category_name = "collectible"
	elif category_name == "boosts":
		singular_category_name = "boost"
	
	if _debug_enabled:
		print("WeightedRandomStrategy: Finding suitable markers for category '%s' with placement_tag '%s'" % [category_name, placement_tag])
		print("WeightedRandomStrategy: Chunk '%s' has %d layout markers" % [chunk_definition.chunk_id, chunk_definition.layout_markers.size()])
	
	for marker in chunk_definition.layout_markers:
		# For obstacles (rocks), only use markers in the ground height zone
		if category_name == "obstacles" and marker.has("height_zone") and marker["height_zone"] != "ground":
			if _debug_enabled:
				print("WeightedRandomStrategy: Skipping non-ground marker for obstacles in height zone '%s'" % marker["height_zone"])
			continue
			
		# Check if marker has intended_category that matches (using singular form)
		if marker.has("intended_category") and (marker["intended_category"] == category_name or marker["intended_category"] == singular_category_name):
			suitable_markers.append(marker.duplicate())
			if _debug_enabled:
				print("WeightedRandomStrategy: Found marker with matching intended_category '%s'" % marker["intended_category"])
		# If placement_tag is "any", any marker is suitable
		elif placement_tag == "any":
			suitable_markers.append(marker.duplicate())
			if _debug_enabled:
				print("WeightedRandomStrategy: Found marker with 'any' placement_tag")
		# Check if marker has tags that include the placement_tag
		elif marker.has("tags") and marker["tags"].has(placement_tag):
			suitable_markers.append(marker.duplicate())
			if _debug_enabled:
				print("WeightedRandomStrategy: Found marker with matching placement_tag '%s'" % placement_tag)
	
	# Debug print the number of suitable markers found
	if _debug_enabled:
		print("DEBUG: Found %d suitable markers for category '%s'" % [suitable_markers.size(), category_name])
		
	# Process each marker based on its placement_mode and height_zone
	for i in range(suitable_markers.size()):
		var marker = suitable_markers[i]
		var original_position = marker.position
		
		# Ensure position is Vector2 (as defined in ChunkDefinition)
		if not original_position is Vector2:
			push_warning("WeightedRandomStrategy: Marker position is not Vector2, converting")
			if original_position is Vector3:
				original_position = Vector2(original_position.x, original_position.z)
				marker.position = original_position
			else:
				original_position = Vector2.ZERO
				marker.position = original_position
				push_error("WeightedRandomStrategy: Invalid marker position type")
		
		# Handle x-coordinate randomization based on placement_mode
		match marker.get("placement_mode", "non-random"):
			"stable-random":
				# Create a seeded RNG based on chunk ID and marker name
				var seeded_rng = RandomNumberGenerator.new()
				var seed_value = hash(chunk_definition.chunk_id + marker.get("name", str(i)))
				seeded_rng.seed = seed_value
				
				# Get randomization range for this category
				var x_min = -5.0
				var x_max = 5.0
				
				# For obstacles (rocks), use a much wider range
				if category_name == "obstacles":
					x_min = -2000.0
					x_max = 2000.0
				
				if content_rules and content_rules.randomization_ranges.has(category_name):
					x_min = content_rules.randomization_ranges[category_name].get("x_min", x_min)
					x_max = content_rules.randomization_ranges[category_name].get("x_max", x_max)
				
				# Generate deterministic but "random" x-coordinate
				var random_x = seeded_rng.randf_range(x_min, x_max)
				marker.position.x = original_position.x + random_x
				
			"fully-random":
				# Get randomization range for this category
				var x_min = -5.0
				var x_max = 5.0
				
				# For obstacles (rocks), use a much wider range
				if category_name == "obstacles":
					x_min = -2000.0
					x_max = 2000.0
				
				if content_rules and content_rules.randomization_ranges.has(category_name):
					x_min = content_rules.randomization_ranges[category_name].get("x_min", x_min)
					x_max = content_rules.randomization_ranges[category_name].get("x_max", x_max)
				
				# Use the regular RNG for truly random positions
				var random_x = _rng.randf_range(x_min, x_max)
				marker.position.x = original_position.x + random_x
				
			# "non-random" is the default - use the exact position specified
		
		# Handle y-coordinate based on height_zone
		if category_name == "obstacles":
			# Always place obstacles (rocks) at ground level (y=0)
			marker.position.y = 0.0
		else:
			# For other content types, use the height zone as specified
			var height_zone = marker.get("height_zone", "specified")
			if height_zone != "specified" and content_rules and content_rules.height_zones.has(height_zone):
				var zone_config = content_rules.height_zones[height_zone]
				
				if zone_config.has("y"):
					# Fixed height (like ground)
					marker.position.y = zone_config.y
				elif zone_config.has("y_min") and zone_config.has("y_max"):
					# Random height within range
					var y_min = zone_config.y_min
					var y_max = zone_config.y_max
					
					if marker.get("placement_mode", "non-random") == "stable-random":
						# Create a seeded RNG based on chunk ID and marker name
						var seeded_rng = RandomNumberGenerator.new()
						var seed_value = hash(chunk_definition.chunk_id + marker.get("name", str(i)) + "y")
						seeded_rng.seed = seed_value
						marker.position.y = seeded_rng.randf_range(y_min, y_max)
					elif marker.get("placement_mode", "non-random") == "fully-random":
						marker.position.y = _rng.randf_range(y_min, y_max)
	
	return suitable_markers

# Check for and fix disallowed patterns in the placements
func _check_and_fix_disallowed_patterns(placements: Array, constraints: Dictionary) -> Array:
	if not constraints.has("disallowed_patterns") or constraints["disallowed_patterns"].is_empty():
		return placements
	
	# Sort placements by distance along chunk
	placements.sort_custom(func(a, b): return a["distance_along_chunk"] < b["distance_along_chunk"])
	
	# Check for disallowed patterns
	for pattern in constraints["disallowed_patterns"]:
		var pattern_parts = pattern.split("_")
		
		# Skip patterns that are too short
		if pattern_parts.size() < 2:
			continue
		
		# Check for pattern matches in the placements
		for i in range(placements.size() - pattern_parts.size() + 1):
			var match_found = true
			
			for j in range(pattern_parts.size()):
				if i + j >= placements.size() or placements[i + j]["category"].to_upper() != pattern_parts[j]:
					match_found = false
					break
			
			# If pattern found, remove the middle element(s)
			if match_found:
				if _debug_enabled:
					print("WeightedRandomStrategy: Found disallowed pattern '%s', removing middle element" % pattern)
				
				# Remove the middle element (for patterns of length 3 or more)
				if pattern_parts.size() >= 3:
					placements.remove_at(i + 1)
				# For patterns of length 2, remove the second element
				else:
					placements.remove_at(i + 1)
				
				# Restart the check since we modified the array
				return _check_and_fix_disallowed_patterns(placements, constraints)
	
	return placements

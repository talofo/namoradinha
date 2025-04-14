class_name WeightedRandomStrategy
extends "res://scripts/stage/strategies/IContentDistributionStrategy.gd"

# Random number generator for consistent randomization
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Debug flag
var _debug_enabled: bool = false

func _init():
    _rng.randomize()

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
    _debug_enabled = enabled

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
    
    # Initialize result array
    var placements = []
    
    # Get content categories and apply difficulty scaling
    var categories = _get_scaled_categories(content_rules, flow_state, difficulty)
    
    # Get placement constraints with difficulty scaling applied
    var constraints = _get_scaled_constraints(content_rules, flow_state, difficulty)
    
    # Determine target counts for each category based on weights
    var target_counts = _calculate_target_counts(categories, constraints, chunk_definition.length)
    
    # Process each category
    for category_name in categories.keys():
        var category = categories[category_name]
        var target_count = target_counts[category_name]
        
        if _debug_enabled:
            print("WeightedRandomStrategy: Placing %d items of category '%s'" % [target_count, category_name])
        
        # Get allowed types for this category
        var allowed_types = category["allowed_types"]
        if allowed_types.is_empty():
            if _debug_enabled:
                print("WeightedRandomStrategy: No allowed types for category '%s', skipping" % category_name)
            continue
        
        # Get preferred marker tag for this category
        var placement_tag = category["placement_tag"]
        
        # Find suitable markers in the chunk
        var suitable_markers = _find_suitable_markers(chunk_definition, category_name, placement_tag)
        
        # Place items
        for i in range(target_count):
            # Select a random type from allowed types
            var type_index = _rng.randi() % allowed_types.size()
            var content_type = allowed_types[type_index]
            
            # Try to place at a marker first
            var position = Vector3.ZERO
            var placed = false
            
            if not suitable_markers.is_empty():
                # Shuffle markers to avoid predictable patterns
                suitable_markers.shuffle()
                
                # Try each marker
                for marker in suitable_markers:
                    position = marker["position"]
                    
                    # Validate placement
                    if validate_placement(position, category_name, content_type, placements, constraints):
                        # Add to placements
                        placements.append({
                            "category": category_name,
                            "type": content_type,
                            "position": position
                        })
                        placed = true
                        break
            
            # If no suitable marker found, generate a procedural position
            if not placed:
                # Try multiple random positions
                for attempt in range(10):  # Limit attempts to avoid infinite loops
                    # Generate a random position along the chunk length
                    var x_offset = _rng.randf_range(-5.0, 5.0)  # Vary across width
                    var z_offset = _rng.randf_range(0, chunk_definition.length)  # Along length
                    position = Vector3(x_offset, 0, z_offset)
                    
                    # Validate placement
                    if validate_placement(position, category_name, content_type, placements, constraints):
                        # Add to placements
                        placements.append({
                            "category": category_name,
                            "type": content_type,
                            "position": position
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
        
        # Apply allowed types modifications
        if flow_scaling.has("allowed_types"):
            for category_name in flow_scaling["allowed_types"].keys():
                if categories.has(category_name):
                    var type_mods = flow_scaling["allowed_types"][category_name]
                    for type_mod in type_mods:
                        if type_mod.begins_with("+"):  # Add type
                            var type_name = type_mod.substr(1)
                            if not categories[category_name]["allowed_types"].has(type_name):
                                categories[category_name]["allowed_types"].append(type_name)
                        elif type_mod.begins_with("-"):  # Remove type
                            var type_name = type_mod.substr(1)
                            categories[category_name]["allowed_types"].erase(type_name)
    
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
func _find_suitable_markers(chunk_definition: ChunkDefinition, category_name: String, placement_tag: String) -> Array:
    var suitable_markers = []
    
    for marker in chunk_definition.layout_markers:
        # Check if marker has intended_category that matches
        if marker.has("intended_category") and marker["intended_category"] == category_name:
            suitable_markers.append(marker)
        # If placement_tag is "any", any marker is suitable
        elif placement_tag == "any":
            suitable_markers.append(marker)
        # Check if marker has tags that include the placement_tag
        elif marker.has("tags") and marker["tags"].has(placement_tag):
            suitable_markers.append(marker)
    
    return suitable_markers

# Check for and fix disallowed patterns in the placements
func _check_and_fix_disallowed_patterns(placements: Array, constraints: Dictionary) -> Array:
    if not constraints.has("disallowed_patterns") or constraints["disallowed_patterns"].is_empty():
        return placements
    
    # Sort placements by z position (along chunk length)
    placements.sort_custom(func(a, b): return a["position"].z < b["position"].z)
    
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

class_name IContentDistributionStrategy
extends RefCounted

# Import required classes
const ChunkDefinition = preload("res://scripts/stage/resources/ChunkDefinition.gd")
const FlowAndDifficultyController = preload("res://scripts/stage/components/FlowAndDifficultyController.gd")
const ContentDistribution = preload("res://scripts/stage/resources/ContentDistribution.gd")

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
    chunk_definition: ChunkDefinition, 
    flow_state: FlowAndDifficultyController.FlowState, 
    difficulty: String, 
    content_rules: ContentDistribution, 
    current_placements_history: Array
) -> Array:
    push_error("IContentDistributionStrategy.distribute_content: Method not implemented")
    return []

# Helper method to validate a potential placement against constraints
# Parameters:
# - position: The proposed position for the content
# - content_category: The category of content (e.g., "obstacles", "boosts")
# - content_type: The specific type within the category (e.g., "Log", "SpeedPad")
# - existing_placements: Array of existing placements to check against
# - constraints: Dictionary of placement constraints from ContentDistribution
# Returns: true if placement is valid, false otherwise
func validate_placement(
    position: Vector3, 
    content_category: String, 
    content_type: String, 
    existing_placements: Array, 
    constraints: Dictionary
) -> bool:
    # Check minimum spacing between same category
    if constraints.has("minimum_spacing") and constraints["minimum_spacing"].has(content_category):
        var min_distance = constraints["minimum_spacing"][content_category]["distance"]
        for placement in existing_placements:
            if placement["category"] == content_category:
                var distance = position.distance_to(placement["position"])
                if distance < min_distance:
                    return false
    
    # Check global minimum spacing between any content
    if constraints.has("minimum_spacing") and constraints["minimum_spacing"].has("any_content"):
        var min_distance = constraints["minimum_spacing"]["any_content"]["distance"]
        for placement in existing_placements:
            var distance = position.distance_to(placement["position"])
            if distance < min_distance:
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
            return false
    
    # All checks passed
    return true

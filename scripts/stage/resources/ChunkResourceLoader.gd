class_name ChunkResourceLoader
extends RefCounted

# Cache of loaded chunks
var _chunk_cache: Dictionary = {}

# Known biomes and height zones
var _biomes: Array = ["default"]
var _height_zones: Array = ["ground", "mid-air", "underground", "stratospheric", "chunk_transitions"]

# Base path for chunks
const BASE_PATH: String = "res://resources/stage/chunks/"

# Debug flag
var _debug_enabled: bool = false

# Initialize with optional configuration
func _init(biomes: Array = [], height_zones: Array = []):
	if not biomes.is_empty():
		_biomes = biomes
	if not height_zones.is_empty():
		_height_zones = height_zones

# Load a chunk by ID
func load_chunk_by_id(chunk_id: String) -> ChunkDefinition:
	# Check cache first
	if _chunk_cache.has(chunk_id):
		return _chunk_cache[chunk_id]
	
	# Try to load using convention-based paths
	var chunk = _load_by_convention(chunk_id)
	
	# If not found, try legacy path (top-level)
	if not chunk:
		chunk = _load_from_legacy_path(chunk_id)
	
	# If still not found, return default
	if not chunk:
		if _debug_enabled:
			push_warning("ChunkResourceLoader: Chunk '%s' not found, using default" % chunk_id)
		return ChunkDefinition.get_default_resource()
	
	# Cache the result
	_chunk_cache[chunk_id] = chunk
	return chunk

# Find all chunks matching criteria
func find_matching_chunks(allowed_types: Array, theme_tags: Array) -> Array:
	var matching_chunks = []
	var checked_paths = {}
	
	# First try convention-based paths
	for biome in _biomes:
		for zone in _height_zones:
			var dir_path = BASE_PATH.path_join(biome).path_join(zone)
			_find_matching_in_directory(dir_path, matching_chunks, allowed_types, theme_tags, checked_paths)
	
	# Then try legacy path (top-level)
	_find_matching_in_directory(BASE_PATH, matching_chunks, allowed_types, theme_tags, checked_paths)
	
	return matching_chunks

# Clear the cache
func clear_cache() -> void:
	_chunk_cache.clear()
	if _debug_enabled:
		print("ChunkResourceLoader: Cache cleared")

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
	_debug_enabled = enabled

# Load a chunk using convention-based paths
func _load_by_convention(chunk_id: String) -> ChunkDefinition:
	for biome in _biomes:
		for zone in _height_zones:
			var path = BASE_PATH.path_join(biome).path_join(zone).path_join("%s.tres" % chunk_id)
			
			if ResourceLoader.exists(path):
				var resource = load(path)
				if resource is ChunkDefinition:
					if resource.validate():
						if _debug_enabled:
							print("ChunkResourceLoader: Loaded chunk '%s' from '%s'" % [chunk_id, path])
						return resource
					else:
						push_warning("ChunkResourceLoader: Validation failed for '%s'" % path)
	
	return null

# Load a chunk from the legacy path (top-level)
func _load_from_legacy_path(chunk_id: String) -> ChunkDefinition:
	var path = BASE_PATH.path_join("%s.tres" % chunk_id)
	
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is ChunkDefinition:
			if resource.validate():
				if _debug_enabled:
					print("ChunkResourceLoader: Loaded chunk '%s' from legacy path '%s'" % [chunk_id, path])
				return resource
			else:
				push_warning("ChunkResourceLoader: Validation failed for '%s'" % path)
	
	return null

# Find matching chunks in a directory
func _find_matching_in_directory(dir_path: String, matching_chunks: Array, allowed_types: Array, theme_tags: Array, checked_paths: Dictionary) -> void:
	var dir = DirAccess.open(dir_path)
	
	if not dir:
		# Instead of just warning, check if this is a known directory that should exist
		var dir_parts = dir_path.split("/")
		var last_part = dir_parts[dir_parts.size() - 1] if dir_parts.size() > 0 else ""
		
		# Only show warning for directories that are expected to exist
		if last_part in _height_zones:
			if _debug_enabled:
				print("ChunkResourceLoader: Creating directory '%s' (was missing)" % dir_path)
			
			# Try to create the directory if it's a known height zone
			var parent_dir = dir_path.get_base_dir()
			if DirAccess.dir_exists_absolute(parent_dir):
				# Create the directory
				DirAccess.make_dir_recursive_absolute(dir_path)
				if _debug_enabled:
					print("ChunkResourceLoader: Created directory '%s'" % dir_path)
				
				# Try opening again
				dir = DirAccess.open(dir_path)
				if not dir:
					return
		else:
			# For unknown directories, just return silently
			return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			# Skip subdirectories - we're already handling them through convention
			pass
		elif file_name.ends_with(".tres"):
			var chunk_path = dir_path.path_join(file_name)
			
			# Skip if already checked
			if checked_paths.has(chunk_path):
				file_name = dir.get_next()
				continue
			
			checked_paths[chunk_path] = true
			
			var resource = load(chunk_path)
			if resource is ChunkDefinition:
				# Check if chunk matches criteria
				var type_match = allowed_types.is_empty() or allowed_types.has(resource.chunk_type)
				
				var tag_match = theme_tags.is_empty()
				if not tag_match:
					for tag in theme_tags:
						if resource.theme_tags.has(tag):
							tag_match = true
							break
				
				if type_match and tag_match:
					matching_chunks.append(resource)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

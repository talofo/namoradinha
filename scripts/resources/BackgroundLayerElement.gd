class_name BackgroundLayerElement
extends Resource

enum TilingMode {
	NONE,
	HORIZONTAL,
	VERTICAL,
	BOTH
}

@export var texture: Texture2D
@export var offset: Vector2
@export var scale: Vector2 = Vector2.ONE
@export var z_index: int = 0
@export var modulate: Color = Color.WHITE
@export var tiling_mode: TilingMode = TilingMode.NONE
@export var region_enabled: bool = false
@export var region_rect: Rect2

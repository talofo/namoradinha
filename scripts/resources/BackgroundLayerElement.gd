class_name BackgroundLayerElement
extends Resource

@export var texture: Texture2D
@export var offset: Vector2
@export var scale: Vector2 = Vector2.ONE
@export var z_index: int = 0
@export var modulate: Color = Color.WHITE

# Note: Tiling is now handled by ParallaxLayer.motion_mirroring in ParallaxLayerController

class_name TransitionHelper
extends RefCounted

static func fade_transition(old_node: CanvasItem, new_node: CanvasItem, 
                           duration: float, completion_callback: Callable) -> Tween:
    var tween = old_node.create_tween()
    tween.tween_property(old_node, "modulate:a", 0.0, duration)
    tween.parallel().tween_property(new_node, "modulate:a", 1.0, duration)
    tween.tween_callback(completion_callback)
    return tween

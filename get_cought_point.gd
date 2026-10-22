extends Node2D


func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("get_cought"):
		body.get_cought()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_method("take_boost"):
		body.take_boost()

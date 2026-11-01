extends Area2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("key"):
		if body.can_open:
			print(2)
			$Sprite2D.show()
			await get_tree().create_timer(0.5).timeout
			get_tree().change_scene_to_file("res://menu_scene.tscn")

extends Control

@export var game_scene: PackedScene

func _ready() -> void:
	var buttons = find_children("*", "Button", true, false)
	

func _on_play_button_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("inspector - game scene - choose")

func _on_options_button_pressed() -> void:
	print("settings open")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

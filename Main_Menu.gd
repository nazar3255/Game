extends Control

@export var game_scene: PackedScene

func _ready() -> void:
	pass
	
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to("level1.tscn")


func _on_settings_button_pressed() -> void:
	print("Відкрито налаштування")

func _on_exit_button_pressed() -> void:
	get_tree().quit()


#_________________то саме для нової менюшки main_menu.tscn ______________________
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://level_1.tscn")

#_________________то саме для нової менюшки main_menu.tscn ______________________
func _on_exit_pressed() -> void:
	get_tree().quit()

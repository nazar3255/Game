extends Control

@export var game_scene: PackedScene

func _ready() -> void:
	# Підключаємо кнопки головного меню кодом
	$VBoxContainer/Play_Button.pressed.connect(_on_play_button_pressed)
	$VBoxContainer/Settings_Button.pressed.connect(_on_settings_button_pressed)
	$VBoxContainer/Exit_Button.pressed.connect(_on_exit_button_pressed)
	
	$VBoxContainer/Play_Button.grab_focus()

func _on_play_button_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("Помилка: Перетягніть сцену level_1 у поле Game Scene в Інспекторі!")

func _on_settings_button_pressed() -> void:
	print("Відкрито налаштування")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

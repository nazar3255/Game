extends CanvasLayer


@export var helth_bar: ProgressBar
@export var pause_menu: Control
@export var main_menu: PackedScene
var player_hp: int


func pause() -> void:
	pause_menu.show()
	get_tree().paused = true

func carry_on() -> void:
	pause_menu.hide()
	get_tree().paused = false

# отримує всі дані для оновлення hud
func set_hp(hp) -> void:
	player_hp = hp
	helth_bar.value = hp

func set_effect() -> void:
	pass

func _ready() -> void:
	print("HUD успішно заспавнився і з'явився в дереві сцен! Позиція: ", $Control.global_position)

func _process(delta: float) -> void:
	pass



func _on_continue_button_pressed() -> void:
	carry_on()

func _on_quit_button_pressed() -> void:
	if main_menu:
		# get_tree().change_scene_to_packed(main_menu)
		pass
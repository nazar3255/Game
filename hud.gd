extends CanvasLayer


@export var helth_bar: ProgressBar
@export var pause_menu: Control
var player_hp: int


# отримує всі дані для оновлення hud
func set_hp(hp) -> void:
	player_hp = hp
	helth_bar.value = hp



func _ready() -> void:
	print("HUD успішно заспавнився і з'явився в дереві сцен! Позиція: ", $Control.global_position)

func _process(delta: float) -> void:
	pass

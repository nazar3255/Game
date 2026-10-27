extends Enemy

@export var trigger_distance: float = 75.0  # Відстань до гравця для вибуху
@export var bomb_damage: int = 50           # Шкода від вибуху нового моба

# Автоматично знаходимо вбудовану бомбу
@onready var bomb_radius: Area2D = $BombaVzruvChechna

var is_exploding: bool = false

func _process(delta: float) -> void:
	# Шукаємо гравця на сцені test_level
	var player = get_tree().current_scene.get_node_or_null("Player")
	
	if player and not is_exploding:
		var distance = global_position.distance_to(player.global_position)
		
		# Перевіряємо відстань
		if distance <= trigger_distance:
			start_countdown()

func start_countdown():
	is_exploding = true
	
	# Зупиняємо моба перед вибухом (якщо швидкість у тебе в enemy.gd — це speed)
	if "speed" in self:
		self.speed = 0
		
	print("Новий камікадзе застиг і готується до вибуху!")
	
	# Ефект спалаху: моб плавно червоніє за 0.3 секунди
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.3)
	
	await get_tree().create_timer(0.3).timeout
	
	# Підриваємо вбудовану бомбу
	if bomb_radius:
		await bomb_radius.execute_explosion(bomb_damage)
		
	# Видаляємо нового моба разом із його колізіями та радіусом вибуху
	queue_free()

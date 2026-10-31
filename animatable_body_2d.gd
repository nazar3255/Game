class_name Bullet
extends Area2D

@export var speed: float = 300.0
@export var damage: int = 10
@export var time_to_fly: float = 3.0
@export var offset: int = 10
var vect: bool = false

var direction: int = 0
var dir_vect: Vector2 = Vector2.ZERO

func is_bullet() -> bool:
	return true

func _ready() -> void:
	await get_tree().create_timer(time_to_fly).timeout
	queue_free()

func setup(dir: int) -> void:
	direction = dir

func setup_vec(dir: Vector2) -> void:
	dir_vect = (dir - Vector2(0, offset)).normalized()
	print("direction", dir_vect, dir)
	direction = -1 if dir_vect.x < 0 else 1
	rotation = dir_vect.angle()
	vect = true

func _physics_process(delta: float) -> void:
	if not vect:
		global_position.x += speed * direction * delta
	elif vect:
		global_position += dir_vect * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("is_bullet") or body.is_in_group("enemies"):
		return
	if body.has_method("is_player"):
		body.take_damage(damage)
		body.take_push(direction)
	queue_free()

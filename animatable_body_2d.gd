class_name Bulet
extends AnimatableBody2D


@export var speed: int
@export var damage: int
@export var time_to_fly: int
var direction: int



func spawn() -> void:
	await get_tree().create_timer(time_to_fly).timeout
	queue_free()

func get_info(dir,hei) -> void:
	global_position.y = hei
	direction = dir

func move(dir, del) -> void:
	global_position.x += speed * dir * del


func _ready() -> void:
	spawn()

func _physics_process(delta) -> void:
	move(direction, delta)



func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("is_player"):
		print("hit")
		body.take_damage(damage)
		body.take_push(direction)
		queue_free()

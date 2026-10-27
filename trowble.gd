class_name Trowble
extends CharacterBody2D

enum Types {NORMAL, JUMPING}

@export var type: Types

@export var speed: int = 200
@export var jump_power: float = 0.5
var direction: int = 1
const g: float = 9.8
var velosity_y: float = 0
var is_jumping: bool = false
var bounce_force: float = 0
var previous_position: Vector2 = Vector2.ZERO
var velocity_c: Vector2 = Vector2.ZERO



func explode() -> void:
	pass

func apply_gravity(delta: float) -> void:
	velosity_y += g * delta
	global_position.y += velosity_y

func move(delta) -> void:
	global_position.x += speed * direction * delta


func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if delta > 0:
		velocity = (global_position - previous_position) / delta
	previous_position = global_position
	apply_gravity(delta)
	move(delta)

func _on_body_entered(body: Node2D) -> void:
	var coord: Vector2 = body.global_position
	var dir = 1 if coord.x > global_position.x else -1 
	if body.has_method("is_player"):
		pass
	else:
		match type:
			Types.NORMAL:
				explode()
			Types.JUMPING:
				if abs(global_position.x - coord.x) > abs(global_position.y - coord.y):
					speed /= -2
				else:
					velosity_y /= -2
				

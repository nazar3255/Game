class_name Trowble
extends CharacterBody2D

enum Types {NORMAL, JUMPING}

@export var type: Types

@export var speed: int = 200
@export var jump_power: float = 0.5
@export var wall_checker: RayCast2D
@export var timer: Timer
@export var base_gravity: float = 1000
@export var fall_multiplier: float = 1.6
@export var max_fall_speed: float = 800
var direction: int = 1
@export var damage: int = 30
const g: float = 98
var velosity_y: float = 0
var is_jumping: bool = false
var velocity_y: float = 0
var pover: int = 100
var previous: Vector2 = Vector2.ZERO
var is_jump = false


func setup(dir, pos: Vector2) -> void:
	print(direction)
	direction = dir
	global_position = pos

func push(dir: Vector2) -> void:
	velocity = dir

func change_direction() -> void:
	direction *= -1
	velocity.x = speed * direction
	wall_checker.target_position.x = 10 * direction

func explode(body) -> void:
	match type:
		Types.NORMAL:
			if body.has_method("is_player"):
				body.take_damage(damage)
			queue_free()
		Types.JUMPING:
			timer.start()
			if body.has_method("is_player"):
				body.take_damage(damage)
				queue_free()
			elif wall_checker.is_colliding():
				change_direction()
			else:
				velocity_y *= -jump_power * 0.5
				velocity.y = velocity_y * 2

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += base_gravity * fall_multiplier * delta
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		velocity.y = 0.0

func vector() -> Vector2:
	var dir_vector = global_position - previous
	previous = global_position
	return dir_vector



func _ready() -> void:
	wall_checker.target_position.x = 10 * direction

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	explode(body)


func _on_timer_timeout() -> void:
	queue_free()

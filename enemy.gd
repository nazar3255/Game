class_name Enemy
extends CharacterBody2D


enum Types_of_move {NORMAL, FLYING, STATIC}
enum Types_of_attack {SHOT_DIRECT, SHOT_VECTOR, BITE, }
enum Directions {RIGHT, LEFT}
enum States {CALM, ATTACK}


@export var move_type: Types_of_move
@export var start_direction: Directions
@export var attack_type: Types_of_attack
var current_state: States = States.CALM


@export var wall_checker: RayCast2D
@export var check_proces: Timer
@export var can_make_turn: Timer
@export var reload_attack: Timer
@export var player_check: Timer
@export var find_player: RayCast2D
@export var bullet: PackedScene
@export var trowble: PackedScene
@export var bullet_spawn: Marker2D


@export var height_of_flying: int = 100
@export var limits_only_x: Vector2 = Vector2(0, 100)
@export var limits_sensitivity: int = 20
@export var speed: int = 100
@export var length_of_view: Vector2 = Vector2(128, 128)
@export var check_eterations: int = 6 
@export var bite_speed: int = 400
@export var base_gravity: float = 1000
@export var fall_multiplier: float = 1.6
@export var max_fall_speed: float = 800
@export var jump_time: float = 0.5
@export var attack_distance: int = 60
@export var use_gravity: bool = true
var direction: int = 1
@export var damage: int = 10
@export var hp: int = 10
var can_turn: bool = true
var target_coord: Vector2
var can_attack: bool = true
const g: float = 9.8


func check_limits() -> void:
	if limits_only_x != Vector2(0,0):
		if global_position.x < limits_only_x.x + limits_sensitivity or global_position.x > limits_only_x.y - limits_sensitivity:
			if current_state != States.ATTACK:
				if (limits_only_x.x + limits_only_x.y) / 2 > global_position.x:
					if direction == -1:
						change_direction()
				elif (limits_only_x.x + limits_only_x.y) / 2 < global_position.x:
					if direction == 1:
						change_direction()
				if global_position.x < limits_only_x.x - limits_sensitivity or global_position.x > limits_only_x.y + limits_sensitivity:
					if current_state != States.ATTACK:
						global_position.x = (limits_only_x.x + limits_only_x.y) / 2
		elif global_position.x < limits_only_x.x or global_position.x > limits_only_x.y:
			global_position.x = (limits_only_x.x + limits_only_x.y) / 2
	
func change_direction(dir=0) -> void:
	if dir != 0:
		direction = clamp(dir, -1, 1)
	else:
		direction *= -1
		bullet_spawn.position.x = direction * 8
	wall_checker.target_position.x = direction * 40
	find_player.target_position.x = length_of_view.x * direction
	can_turn = false
	can_make_turn.start()

func get_player_pos() -> Vector2:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		return player.global_position
	return Vector2.ZERO

func calculate_velocity(target_pos: Vector2, time) -> Vector2:
	var vel_x = (target_pos.x - global_position.x) / time
	var vel_y = ((target_pos.y - global_position.y) - 0.5 * g * time * time) / time
	return Vector2(vel_x, vel_y)

func shot_vector() -> void:
	if not bullet:
		print("Bullet scene is null!")
		return
	var b = bullet.instantiate()
	get_parent().add_child(b)
	if bullet_spawn:
		b.global_position = bullet_spawn.global_position
	else:
		b.global_position = global_position
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var dir = player.global_position - global_position
	b.setup_vec(dir)

func shot_direct() -> void:
	if not bullet:
		print("Bullet scene is null!")
		return
	var b = bullet.instantiate()
	get_parent().add_child(b)
	if bullet_spawn:
		b.global_position = bullet_spawn.global_position
	else:
		b.global_position = global_position
	b.setup(direction)

func bite() -> void:
	if move_type == Types_of_move.NORMAL:
		var vel = calculate_velocity(target_coord, jump_time)
		velocity.x += vel.x
		velocity.y += -vel.y * 50 * jump_time
		print(velocity.y)
		await get_tree().create_timer(jump_time).timeout
		velocity.x = 0
		var target = find_player.get_collider()
		var dist
		if target and target.has_method("is_player"):
			target_coord = target.global_position
			dist = abs(global_position.x - target.global_position.x)
		print(dist)
		if target:
			await get_tree().create_timer(0.2).timeout
			if dist <= attack_distance and target.global_position.x * direction > global_position.x * direction:
				target.take_damage(damage)
	if move_type == Types_of_move.FLYING:
		var dir_to_player = global_position.direction_to(target_coord)
		dir_to_player.x += 0.5 * direction
		dir_to_player = dir_to_player.normalized()
		velocity = dir_to_player * (speed * 3)
		await get_tree().create_timer(0.5).timeout
		var player = get_tree().get_first_node_in_group("player") as Node2D
		if player:
			var dist_x = abs(global_position.x - player.global_position.x)
			print("Відстань по X: ", dist_x)
			if dist_x <= attack_distance:
				if player.has_method("take_damage"):
					player.take_damage(damage)
		velocity = Vector2(direction * speed, -speed * 2)
		await get_tree().create_timer(0.2).timeout
		velocity = Vector2.ZERO
		current_state = States.CALM
		
	
func attack() -> void:
	current_state = States.ATTACK
	if can_attack:
		can_attack = false
		await get_tree().create_timer(0.2).timeout
		reload_attack.start()
		velocity.x = 0
		print("attack")
		match attack_type:
			Types_of_attack.BITE:
				bite()
			Types_of_attack.SHOT_DIRECT:
				shot_direct()
			Types_of_attack.SHOT_VECTOR:
				shot_vector()

func die() -> void:
	print("mob die")
	queue_free()

func take_damage(amount) -> void:
	print("damage taken")
	hp -= amount
	if hp <= 0:
		die()

func check_player() -> void:
	player_check.start()
	if current_state == States.CALM:
		var amount = length_of_view.y / check_eterations
		var top_bottom: int
		if move_type == Types_of_move.FLYING:
			top_bottom = 1
		else:
			top_bottom = -1
		if check_eterations:
			find_player.target_position.y = 0
			for i in range(check_eterations):
				find_player.target_position.y += amount * top_bottom
				if find_player.is_colliding():
					var target = find_player.get_collider()
					if target and target.has_method("is_player"):
						target_coord = target.global_position
						attack()
						return
				await get_tree().create_timer(0.1 / check_eterations).timeout
			find_player.target_position.y = 0
			return

func check_barriers() -> void:
	if current_state == States.CALM:
		match move_type:
			Types_of_move.NORMAL:
				if wall_checker.is_colliding() and is_on_floor():
					if can_turn:
						change_direction()
			Types_of_move.FLYING:
				if wall_checker.is_colliding():
					if can_turn:
						change_direction()

func move() -> void:
	if current_state == States.CALM:
		match move_type:
			Types_of_move.NORMAL:
				velocity.x = speed * direction
			Types_of_move.FLYING:
				velocity.x = speed * direction
				if global_position.y != height_of_flying:
					if abs(global_position.y + height_of_flying) <= 1:
						velocity.y = 0
						global_position.y = -height_of_flying
					elif global_position.y < -height_of_flying:
						velocity.y = speed
					elif global_position.y > -height_of_flying:
						velocity.y = -speed
				else:
					velocity.y = 0
			Types_of_move.STATIC:
				velocity.x = 0

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += base_gravity * fall_multiplier * delta
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		if current_state != States.ATTACK:
			velocity.y = 0.0


func _ready() -> void:
	add_to_group("enemies")
	if limits_only_x != Vector2(0,0):
		if global_position.x < limits_only_x.x or global_position.x > limits_only_x.y:
			global_position.x = (limits_only_x.x + limits_only_x.y) / 2
	if start_direction == Directions.RIGHT:
		direction = 1
	elif start_direction == Directions.LEFT:
		direction = -1
	else:
		direction = 1
	bullet_spawn.position.x = direction * 8
	find_player.target_position.x = length_of_view.x * direction
	wall_checker.target_position.x = direction * 40
	check_proces.start()

func _physics_process(delta: float) -> void:
	if move_type != Types_of_move.FLYING and use_gravity:
		apply_gravity(delta)
	move()
	move_and_slide()


func _on_can_turn_timeout() -> void:
	can_turn = true

func _on_check_proces_timeout() -> void:
	check_barriers()
	check_limits()
	check_player()

func _on_attack_reload_timeout() -> void:
	can_attack = true
	if find_player.is_colliding():
		attack()


func _on_player_check_timeout() -> void:
	if find_player.is_colliding():
		var target = find_player.get_collider()
		if target and not target.has_method("is_player"):
			current_state = States.CALM
	elif not find_player.is_colliding():
		current_state = States.CALM

class_name Enemy
extends CharacterBody2D


enum Types_of_move {NORMAL, FLYING, STATIC}
enum Types_of_attack {SHOT_DIRECT, SHOT_VECTOR, BITE, EXPLOSION, TROW}
enum Directions {RIGHT, LEFT}
enum States {CALM, ATTACK}


@export var move_type: Types_of_move
@export var start_direction: Directions
@export var attack_type: Types_of_attack
var current_state: States = States.CALM

enum BitePhase {NONE, WINDUP, DASH, RETREAT}
var bite_phase: BitePhase = BitePhase.NONE
var bite_time_left: float = 0.0
var bite_dir: Vector2 = Vector2.ZERO
var bite_hit_done: bool = false

@export var bite_windup: float = 0.3
@export var bite_dash_time: float = 0.5
@export var bite_retreat_time: float = 0.35
@export var bite_hit_radius: float = 32.0


@export var wall_checker: RayCast2D
@export var check_proces: Timer
@export var can_make_turn: Timer
@export var reload_attack: Timer
@export var player_check: Timer
@export var find_player: RayCast2D
@export var bullet: PackedScene
@export var trowble: PackedScene
@export var bullet_spawn: Marker2D
@export var sprite: Sprite2D


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
@export var explode_distance: int = 120
@export var expl_time: float = 3
@export var use_gravity: bool = true
var direction: int = 1
@export var damage: int = 10
@export var explosion_damage: int = 200
@export var hp: int = 10
var can_turn: bool = true
var target_coord: Vector2
var can_attack: bool = true
const g: float = 9.8
var is_chase: bool = false


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
	if sprite:
		sprite.flip_h = direction < 0
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

func throw() -> void:
	if not trowble:
		print("Trowble scene is null!")
		return
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var dist_x = abs(player.global_position.x - global_position.x)
	var forse = Vector2(direction * sqrt(dist_x * g) * 9, -sqrt(dist_x * g) * 10)
	var t = trowble.instantiate()
	var spawn_pos = global_position + Vector2(5 * direction, 0)
	get_parent().add_child(t)
	t.setup(direction, spawn_pos)
	t.push(forse)
	current_state = States.ATTACK

func explode() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	await get_tree().create_timer(expl_time).timeout
	var dist = global_position.distance_to(player.global_position)
	for i in range(5):
		print(i)
		if dist <= explode_distance:
			await get_tree().create_timer(0.2).timeout
			dist = global_position.distance_to(player.global_position)
			if dist <= explode_distance:
				player.take_damage(explosion_damage / (dist / 10))
			queue_free()
			return
		await get_tree().create_timer(expl_time).timeout
	current_state = States.CALM
	is_chase = false
	change_direction()
	
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

func start_flying_bite() -> void:
	current_state = States.ATTACK
	bite_phase = BitePhase.WINDUP
	bite_time_left = bite_windup
	bite_hit_done = false
	velocity = Vector2.ZERO

func end_flying_bite() -> void:
	bite_phase = BitePhase.NONE
	velocity = Vector2.ZERO
	current_state = States.CALM
	can_turn = true

func start_retreat() -> void:
	bite_phase = BitePhase.RETREAT
	bite_time_left = bite_retreat_time
	var away_x: int = -int(sign(bite_dir.x)) if bite_dir.x != 0 else -direction
	change_direction(away_x)
	velocity = Vector2(away_x, -1).normalized() * speed * 2

func update_flying_bite(delta: float) -> void:
	var target = get_tree().get_first_node_in_group("player") as Node2D
	bite_time_left -= delta

	match bite_phase:
		BitePhase.WINDUP:
			velocity = Vector2.ZERO
			if bite_time_left <= 0.0:
				if not is_instance_valid(target):
					end_flying_bite()
					return
				bite_dir = global_position.direction_to(target.global_position)
				if bite_dir.x != 0:
					change_direction(int(sign(bite_dir.x)))
				velocity = bite_dir * speed * 3
				bite_phase = BitePhase.DASH
				bite_time_left = bite_dash_time

		BitePhase.DASH:
			if not bite_hit_done and is_instance_valid(target):
				if global_position.distance_to(target.global_position) <= bite_hit_radius:
					bite_hit_done = true
					if target.has_method("take_damage"):
						target.take_damage(damage)
						target.take_push(direction)
					start_retreat()
					return
			if bite_time_left <= 0.0 or is_on_wall() or is_on_floor():
				start_retreat()

		BitePhase.RETREAT:
			if bite_time_left <= 0.0:
				end_flying_bite()

func bite() -> void:
	var target = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(target):
		current_state = States.CALM
		return
	if move_type == Types_of_move.NORMAL:
		velocity.x = 0
		await get_tree().create_timer(jump_time).timeout
		target_coord = target.global_position
		var gravity = base_gravity * fall_multiplier
		var dx = target_coord.x - global_position.x
		var dy = target_coord.y - global_position.y
		velocity.x = dx / jump_time
		velocity.y = (dy - 0.5 * gravity * jump_time * jump_time) / jump_time
		await get_tree().create_timer(jump_time).timeout
		velocity.x = 0
		var dist = abs(global_position.x - target.global_position.x)
		var in_front = (target.global_position.x - global_position.x) * direction > 0
		if dist <= attack_distance and in_front:
			if target.has_method("take_damage"):
				target.take_damage(damage)
	elif move_type == Types_of_move.FLYING:
		start_flying_bite()
	
func attack() -> void:
	current_state = States.ATTACK
	if can_attack and attack_type != Types_of_attack.EXPLOSION:
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
			Types_of_attack.TROW:
				throw()

func die() -> void:
	print("mob die")
	var material = sprite.material as ShaderMaterial
	material.set_shader_parameter("flash_intensity", 1.0)
	await get_tree().create_timer(1.0).timeout
	queue_free()

func take_damage(amount) -> void:
	print("damage taken")
	hp -= amount
	if hp <= 0:
		die()

func come_closer(targ) -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	current_state = States.ATTACK
	match move_type:
		Types_of_move.STATIC:
			if global_position.distance_to(player.global_position) <= explode_distance:
				explode()
		Types_of_move.NORMAL:
			direction = 1 if player.global_position.x > global_position.x else -1
			is_chase = true
			await get_tree().create_timer(0.5).timeout
			explode()
			if global_position.distance_to(player.global_position) <= explode_distance / 3:
				is_chase = false
				velocity.x = 0
			else:
				current_state = States.CALM
				is_chase = false
				

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
						if attack_type != Types_of_attack.EXPLOSION:
							attack()
							return
						else:
							if move_type != Types_of_move.STATIC:
								come_closer(target)
							else:
								explode()
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
	if current_state == States.CALM or is_chase:
		$AnimationPlayer.play("move")
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
	if bite_phase != BitePhase.NONE:
		update_flying_bite(delta)
	else:
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
	if bite_phase != BitePhase.NONE:
		return
	if find_player.is_colliding():
		var target = find_player.get_collider()
		if target and not target.has_method("is_player"):
			current_state = States.CALM
	elif not find_player.is_colliding():
		current_state = States.CALM

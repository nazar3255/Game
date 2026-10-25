extends CharacterBody2D


@export var speed: int = 250
@export var jump_hight: int = -100
var direction: int = 1
@export var dash_speed: int = 70
var axeleration: int = 10
var is_dash: bool = false
var can_dash: bool = true
var can_jump: bool = true
var can_attack: bool = true
@export var damage: int = 10
@export var hp: int = 100
@export var base_gravity: float = 1000
@export var fall_multiplier: float = 1.6
@export var max_fall_speed: float = 800
var is_cought: bool = false
var can_move: bool = true


func is_player() -> bool:
	return true

func take_push(mob_direction, pow=1) -> void:
	if not is_cought:
		velocity.x = 0
		can_move = false
		velocity.x = speed * mob_direction * 2 * pow
		$can_move.start()
		await get_tree().create_timer(0.2).timeout
		velocity.x = 0
	
func get_cought() -> void:
	velocity.y = 0
	is_cought = true
	can_jump = true

func take_boost() -> void:
	velocity.x += direction * speed * 0.7
		
func attack() -> void:
	can_attack = false
	$AnimationPlayer.play("attack")
	$attack_reload.start()
	$slise_effect.visible = true
	var overlapping_bodies = $attack_box.get_overlapping_bodies()
	for i in overlapping_bodies:
		if i.has_method("take_damage"):
			i.take_damage(damage)
	
func take_damage(amount) -> void:
	hp -= amount
	print(hp)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += base_gravity * fall_multiplier * delta
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		velocity.y = 0.0


func _ready() -> void:
	add_to_group("player")
	$slise_effect.visible = false
	$attack_box.position.x = 32 * direction
	$slise_effect.position.x = 40 * direction

func _physics_process(delta: float) -> void:
	if not is_cought:
		apply_gravity(delta)

	if Input.is_action_pressed("left()") and can_move:
		if not is_cought:
			direction = -1
			$attack_box.position.x = 32 * direction
			$slise_effect.position.x = 40 * direction
			$slise_effect.flip_h = true
			$Sprite2D.flip_h = true
			if is_dash == false:
				if velocity.x > -speed:
					velocity.x += speed * delta * direction * axeleration
			else:
				velocity.y = 0
				velocity.x += dash_speed * delta * direction * axeleration ** 2

	elif Input.is_action_pressed("right()") and can_move:
		if not is_cought:
			direction = 1
			$attack_box.position.x = 32 * direction
			$slise_effect.position.x = 40 * direction
			$Sprite2D.flip_h = false
			$slise_effect.flip_h = false
			if is_dash == false:
				if velocity.x < speed:
					velocity.x += speed * delta * direction * axeleration
			else:
				velocity.y = 0
				velocity.x += dash_speed * delta * direction * axeleration ** 2

	else:
		if is_dash == false:
			if can_move:
				if velocity.x * direction <= 10:
					velocity.x = 0
				else:
					velocity.x -= axeleration * direction * 2
			
		else:
			velocity.y = 0
			velocity.x += dash_speed * delta * direction * axeleration ** 2
		

	if not is_on_floor():
		if $jump_in_air.is_stopped():
			$jump_in_air.start()
	else:
		can_jump = true

	if Input.is_action_just_pressed("dash()") and not is_cought and can_move:
		if can_dash == true:
			is_dash = true
			$dash.start()
			can_dash = false

	if Input.is_action_pressed("up()") and can_jump == true and not Input.is_action_pressed("down_dash()") and can_move:
		if not is_cought:
			velocity.y += jump_hight * 5
			can_jump = false
		else:
			is_cought = false
			velocity.y += jump_hight * 6.1
			can_jump = false

	if Input.is_action_pressed("down_dash()") and not is_on_floor() and $dash.is_stopped() and can_move:
		velocity.y += dash_speed * 2
		is_cought = false

	move_and_slide()
	if Input.is_action_just_pressed("attack()") and can_attack:
		attack()


func _on_dash_timeout() -> void:
	is_dash = false
	velocity.x = speed * direction
	$dash_reload.start()

func _on_dash_reload_timeout() -> void:
	can_dash = true

func _on_jump_in_air_timeout() -> void:
	if not is_cought:
		can_jump = false

func _on_attack_reload_timeout() -> void:
	can_attack = true
	$slise_effect.visible = false

func _on_can_move_timeout() -> void:
	can_move = true

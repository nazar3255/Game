extends CharacterBody2D


const speed = 250.0
const jump_hight = -100
var direction = 1
var dash_speed = 70
var axeleration = 10
var is_dash = false
var can_dash = true
var can_jump = true
var gravity_a = 9.8
var can_attack = true
var damage = 10
var hp = 100
var is_cought = false
var can_move = true


func take_push(mob_direction):
	if not is_cought:
		velocity.x += speed * mob_direction
		velocity.y += jump_hight * 3
		can_move = false
		$can_move.start()
	
func get_cought() -> void:
	velocity.y = 0
	is_cought = true
	can_jump = true

func take_boost():
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

func _ready() -> void:
	$slise_effect.visible = false
	$attack_box.position.x = 32 * direction
	$slise_effect.position.x = 40 * direction


func _physics_process(delta: float) -> void:
	if not is_on_floor() and not is_cought:
		velocity.y += gravity_a ** 2 *axeleration * delta * (1 / (gravity_a ** 2 / 100)) * 1.667

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

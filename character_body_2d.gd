extends CharacterBody2D


const speed = 100.0
const jump_height = -400.0
var gravity_a = 9.8
var axeleration = 10
var direction = 1
var can_turn = true
var is_attacking = false
var hp = 30


func die():
	print("mob die")
	queue_free()

func take_damage(amount):
	print("damage taken")
	hp -= amount
	if hp <= 0:
		die()

func attack():
	is_attacking = true
	var coordinates = $find_player.get_collision_point()
	print(coordinates)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity_a ** 2 *axeleration * delta * (1 / (gravity_a ** 2 / 100)) * 1.667

	if $wall_cheker.is_colliding() and is_on_floor():
		if can_turn:
			direction *= -1
			can_turn = false
			$can_turn.start()
	if direction == 1:
		$wall_cheker.target_position.x = 40
		$find_player.target_position.x = 60
		$"fit_back area".position.x = 0
	else:
		$wall_cheker.target_position.x = -40
		$find_player.target_position.x = -60
		$"fit_back area".position.x = -58
	velocity.x = speed * direction
	move_and_slide()

	if $find_player.is_colliding():
		attack()

func _on_can_turn_timeout() -> void:
	can_turn = true

func _on_fit_back_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_push"):
		body.take_push(direction)

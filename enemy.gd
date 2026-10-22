extends CharacterBody2D

var gravity_a = 9.8
var axeleration = 10
var hp = 30

func die():
	print("Enemy die")

func take_damage(amount):
	hp -= amount 
	if hp <= 0:
		die()
		
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity_a ** 2 *axeleration * delta * (1 / (gravity_a ** 2 / 100)) * 1.667

	move_and_slide()

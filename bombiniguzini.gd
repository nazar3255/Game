extends Area2D

func _ready() -> void:
	monitoring = false
	position = Vector2.ZERO

func _process(_delta: float) -> void:
	position = Vector2.ZERO

func execute_explosion(damage: int, knockback_force: float):
	monitoring = true
	
	await get_tree().physics_frame
	
	var bodies = get_overlapping_bodies()
	print("Тіла в радіусі вибуху: ", bodies)
	
	for body in bodies:
		if body.name == "Player":
			print("Знайдено гравця! Намагаємось нанести урон...")
			
			var push_direction = (body.global_position - global_position).normalized()
			var knockback_vector = push_direction * knockback_force
			
			if body.has_method("take_damage_with_knockback"):
				body.take_damage_with_knockback(damage, knockback_vector)
			elif body.has_method("take_damage"):
				body.take_damage(damage)
				if "velocity" in body: body.velocity = knockback_vector
			elif body.has_method("hit"):
				body.hit(damage)
				if "velocity" in body: body.velocity = knockback_vector
			else:
				if "health" in body:
					body.health -= damage
					print("Функцію не знайдено, але здоров'я зменшено напряму. Поточне HP: ", body.health)
				if "velocity" in body:
					body.velocity = knockback_vector
			
			if body.has_method("move_and_slide"):
				body.move_and_slide()
				
			break
			
	queue_free()

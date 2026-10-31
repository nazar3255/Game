extends CharacterBody2D


enum States {NORMAL, EFFECT}
@export var hud: PackedScene
var hud_instance: CanvasLayer
@export var effect_material: ShaderMaterial
@export var effect_shader: ColorRect
@export var gloving: ShaderMaterial
@export var global_shder: ColorRect
@export var light: PointLight2D
@export var slise_effect: Sprite2D
@export var sprite: Sprite2D
@export var attack_box: Area2D
@export var reload_effect: Timer
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
@export var max_hp: int = 100
@export var base_gravity: float = 1000
@export var fall_multiplier: float = 1.6
@export var max_fall_speed: float = 800
var is_cought: bool = false
var can_move: bool = true
var hp: int
var can_effect: bool = true
var current_state: States = States.NORMAL


func is_player() -> bool:
	return true

func effect(color: Color = Color("#85aec1"), time: float = 7) -> void:
	if can_effect:
		effect_shader.show()
		effect_material.set_shader_parameter("tint_color", color)
		var tween := create_tween()
		tween.tween_method(
			func(value) -> void:
				effect_material.set_shader_parameter("intensity", value)
				gloving.set_shader_parameter("emission", value * 2)
				light.energy = value,
			0.0,
			1.0,
			0.2
		)
		current_state = States.EFFECT
		can_effect = false
		reload_effect.start(time)

func take_push(mob_direction, pow=1) -> void:
	if not is_cought:
		velocity.x = 0
		can_move = false
		velocity.x = speed * mob_direction * 1.5 * pow
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
	$AnimationPlayer2.play("attack")
	$attack_reload.start()
	slise_effect.visible = true
	var overlapping_bodies = $attack_box.get_overlapping_bodies()
	for i in overlapping_bodies:
		if i.has_method("take_damage"):
			i.take_damage(damage)
	
func take_damage(amount) -> void:
	hp -= amount
	hp = clamp(hp, 0, max_hp)
	#оновлений варіант
	hud_instance.set_hp(hp)
	print(hp)

func apply_gravity(delta: float) -> void:

	if not is_on_floor():
		velocity.y += base_gravity * fall_multiplier * delta
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		velocity.y = 0.0

func change_direction(dir: int = 1) -> void:
	direction = dir
	if slise_effect:
		slise_effect.position.x = 20 * dir
		if dir == 1:
			slise_effect.flip_h = false
		else:
			slise_effect.flip_h = true
	if sprite:
		if dir == 1:
			sprite.flip_h = false
		else:
			sprite.flip_h = true
	if attack_box:
		attack_box.position.x = 16 * dir
		
func move(dir, delta) -> void:
	if is_dash == false:
		if velocity.x < speed and dir == 1:
			velocity.x += speed * delta * dir * axeleration
			$AnimationPlayer.play("run")
		elif velocity.x > -speed and dir == -1:
			velocity.x += speed * delta * dir * axeleration
			$AnimationPlayer.play("run")
	else:
		velocity.y = 0
		velocity.x += dash_speed * delta * dir * axeleration ** 2
		$AnimationPlayer.play("stand")
	

func _ready() -> void:
	effect_shader.hide()
	global_shder.show()
	effect_material.set_shader_parameter("intensity", 0)

	hp = max_hp
	if hud:
		hud_instance = hud.instantiate()
		add_child(hud_instance)
		hud_instance.visible = true

	#дані передаються через функціЇ set_назва того що передаєш()
	#на початку обов'язково оновити всі дані
	hud_instance.set_hp(hp)


	add_to_group("player")
	$slise_effect.visible = false
	$attack_box.position.x = 16 * direction
	$slise_effect.position.x = 20 * direction

func _physics_process(delta: float) -> void:
	if not is_cought:
		apply_gravity(delta)

	if Input.is_physical_key_pressed(KEY_ESCAPE):
		if get_tree().paused == false:
			hud_instance.pause()

	if velocity.x == 0:
		$AnimationPlayer.play("stand")

	if Input.is_action_pressed("left()") and can_move:
		if not is_cought:
			change_direction(-1)
			move(direction, delta)
			

	elif Input.is_action_pressed("right()") and can_move:
		if not is_cought:
			change_direction(1)
			move(direction, delta)
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
		
	if is_cought:
		$AnimationPlayer.play("climb")
		if direction == 1:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	if not is_on_floor():
		if $jump_in_air.is_stopped():
			$jump_in_air.start()
	else:
		can_jump = true

	if Input.is_action_just_pressed("dash()") and not is_cought and can_move:
		if can_dash == true:
			$AnimationPlayer.play("run")
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

	if Input.is_action_just_pressed("vision_effect()") and can_attack:
		# effect(Color("#50e56b"), 0.3)
		effect()


func _on_dash_timeout() -> void:
	is_dash = false
	velocity.x = speed * direction
	$dash_reload.start()
	if Input.is_action_pressed("left()") and can_move or Input.is_action_pressed("right()") and can_move:
		$AnimationPlayer.play("run")

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
	


func _on_relload_effect_timeout() -> void:
	current_state = States.NORMAL
	var tween = create_tween()
	tween.tween_method(
			func(value) -> void:
				effect_material.set_shader_parameter("intensity", value)
				gloving.set_shader_parameter("emission", clamp(value * 2, 1, 10))
				light.energy = value,
			1.0,
			0.0,
			0.5
		)
	await get_tree().create_timer(0.3).timeout
	can_effect = true
	effect_shader.hide()

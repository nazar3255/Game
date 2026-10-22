extends RigidBody2D


var hp = 30


func take_damage(amount):
	hp -= amount
func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass

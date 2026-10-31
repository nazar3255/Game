extends PathFollow2D

## Speed of the platform in pixels per second
@export var speed: float = 100.0

## Toggle movement on/off
@export var is_moving: bool = true

# Internal direction tracker (1 for forward, -1 for reverse)
var _direction: int = 1


func _physics_process(delta: float) -> void:
	if not is_moving:
		return

	# Calculate how much ratio to add based on total path length
	var curve_length: float = get_parent().curve.get_baked_length()
	if curve_length == 0.0:
		return

	# Move progress ratio safely
	progress_ratio += (speed / curve_length) * delta * _direction

	# Ping-pong bounds check
	if progress_ratio >= 1.0:
		progress_ratio = 1.0
		_direction = -1
	elif progress_ratio <= 0.0:
		progress_ratio = 0.0
		_direction = 1

extends AudioStreamPlayer2D

@export var sound: AudioStream 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AudioStream.stream = sound
	$AudioStream.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

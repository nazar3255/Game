extends Line2D

@export var point_distance: float = 2.0
@export var max_points: int = 60
@export var fade_speed: float = 4.0

var player: CharacterBody2D
var last_position: Vector2
var trail_alpha: float = 0.0


func _ready() -> void:
    player = get_parent() as CharacterBody2D

    set_as_top_level(true)
    global_position = Vector2.ZERO

    width = 12.0
    default_color = Color(0.6, 0.8, 1.0, 0.8)
    z_index = -1

    # Тонкий початок, товстий кінець біля гравця
    width_curve = Curve.new()
    width_curve.add_point(Vector2(0.0, 0.0))
    width_curve.add_point(Vector2(1.0, 1.0))

    clear_points()


func _process(delta: float) -> void:
    if player == null:
        return

    if player.is_dash:
        trail_alpha = 1.0

        var current_position = player.global_position

        if get_point_count() == 0:
            add_point(current_position)
            last_position = current_position

        elif current_position.distance_to(last_position) >= point_distance:
            add_point(current_position)
            last_position = current_position

        while get_point_count() > max_points:
            remove_point(0)

    else:
        trail_alpha = move_toward(trail_alpha, 0.0, fade_speed * delta)

        if trail_alpha <= 0.0:
            clear_points()

    modulate.a = trail_alpha
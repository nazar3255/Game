
extends ColorRect

@export var fog_camera: Camera2D

var fog_material: ShaderMaterial


func _ready() -> void:
    fog_material = material as ShaderMaterial

    if fog_material == null:
        push_error("Atmospheric Fog: ShaderMaterial не знайдено!")
        return

    if fog_camera == null:
        push_error("Atmospheric Fog: Camera2D не призначена!")
        return

    # Створюємо окремий екземпляр матеріалу
    fog_material = fog_material.duplicate() as ShaderMaterial
    material = fog_material

    update_fog_position()


func _process(_delta: float) -> void:
    if fog_material == null or fog_camera == null:
        return

    update_fog_position()


func update_fog_position() -> void:
    fog_material.set_shader_parameter(
        "camera_world_position",
        fog_camera.global_position
    )

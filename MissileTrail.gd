extends GPUParticles3D

@export var auto_destroy: bool = true
@export var destroy_delay: float = 2.0

func _ready() -> void:
    # Автоматически удаляем после завершения
    if auto_destroy:
        await get_tree().create_timer(lifetime + destroy_delay).timeout
        queue_free()

func set_color(color: Color) -> void:
    # Настраиваем цвет частиц
    var material = process_material as ParticleProcessMaterial
    if material:
        material.color = color

func set_speed(initial_speed: float) -> void:
    # Настраиваем скорость частиц в зависимости от скорости ракеты
    var material = process_material as ParticleProcessMaterial
    if material:
        material.initial_velocity_min = initial_speed * 0.5
        material.initial_velocity_max = initial_speed

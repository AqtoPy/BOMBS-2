extends Node3D

@onready var explosion_particles: GPUParticles3D = $ExplosionParticles
@onready var shockwave_particles: GPUParticles3D = $ShockwaveParticles
@onready var light: OmniLight3D = $OmniLight3D
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var auto_destroy: bool = true
@export var light_fade_speed: float = 5.0
@export var max_light_intensity: float = 10.0

var initial_light_intensity: float = 0.0

func _ready() -> void:
    # Запоминаем начальную интенсивность света
    if light:
        initial_light_intensity = light.light_energy
    
    # Запускаем все эффекты
    start_explosion_effects()
    
    # Автоматически удаляем после завершения
    if auto_destroy:
        await get_tree().create_timer(explosion_particles.lifetime + 1.0).timeout
        queue_free()

func start_explosion_effects() -> void:
    # Запускаем частицы
    explosion_particles.emitting = true
    shockwave_particles.emitting = true
    
    # Включаем свет
    if light:
        light.light_energy = max_light_intensity
    
    # Проигрываем звук
    if audio_player:
        audio_player.play()

func _process(delta: float) -> void:
    # Плавно уменьшаем интенсивность света
    if light and light.light_energy > initial_light_intensity:
        light.light_energy = lerp(light.light_energy, initial_light_intensity, light_fade_speed * delta)

func set_explosion_size(size: float) -> void:
    # Масштабируем эффект взрыва
    var scale_factor = size / 5.0  # 5.0 - базовый размер
    
    # Масштабируем частицы
    explosion_particles.scale = Vector3.ONE * scale_factor
    shockwave_particles.scale = Vector3.ONE * scale_factor
    
    # Настраиваем количество частиц
    explosion_particles.amount = int(100 * scale_factor)
    
    # Настраиваем свет
    if light:
        light.omni_range = size * 2

func set_explosion_color(color: Color) -> void:
    # Настраиваем цвет взрыва
    var explosion_material = explosion_particles.process_material as ParticleProcessMaterial
    var shockwave_material = shockwave_particles.process_material as ParticleProcessMaterial
    
    if explosion_material:
        explosion_material.color = color
    
    if shockwave_material:
        shockwave_material.color = color.lightened(0.3)

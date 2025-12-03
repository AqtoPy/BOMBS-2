extends Area3D

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var timer: Timer = $Timer

@export var damage: float = 50.0
@export var radius: float = 5.0
@export var max_damage_range: float = 2.0
@export var damage_type: String = "explosive"
@export var faction: String = "neutral"  # neutral, player, enemy

var damage_applied: bool = false

func _ready() -> void:
    # Настраиваем размер области взрыва
    setup_explosion_area()
    
    # Запускаем таймер для нанесения урона
    timer.wait_time = 0.1  # Небольшая задержка перед нанесением урона
    timer.start()
    
    # Удаляем через 5 секунд
    await get_tree().create_timer(5.0).timeout
    queue_free()

func setup_explosion_area() -> void:
    # Настраиваем коллизию
    if collision_shape:
        var shape = SphereShape3D.new()
        shape.radius = radius
        collision_shape.shape = shape
    
    # Настраиваем частицы
    if particles:
        particles.scale = Vector3.ONE * (radius / 2.5)
        particles.emitting = true

func apply_damage() -> void:
    if damage_applied:
        return
    
    damage_applied = true
    var bodies = get_overlapping_bodies()
    
    for body in bodies:
        # Проверяем, можно ли нанести урон этому телу
        if should_damage_body(body):
            var distance = global_position.distance_to(body.global_position)
            var calculated_damage = calculate_damage(distance)
            
            if calculated_damage > 0:
                inflict_damage(body, calculated_damage)

func should_damage_body(body: Node) -> bool:
    # Не наносим урон самому себе или дружественным целям
    var body_faction = get_body_faction(body)
    
    # Правила нанесения урона:
    if faction == "neutral":
        return true  # Нейтральный взрыв поражает всех
    elif faction == "player":
        return body_faction != "player"  # Игрок не попадает под урон своих взрывов
    elif faction == "enemy":
        return body_faction != "enemy"   # Враги не попадают под урон своих взрывов
    
    return true

func get_body_faction(body: Node) -> String:
    # Определяем фракцию тела
    if body.has_method("get_faction"):
        return body.get_faction()
    elif body.is_in_group("player"):
        return "player"
    elif body.is_in_group("enemy"):
        return "enemy"
    
    return "neutral"

func calculate_damage(distance: float) -> float:
    if distance > radius:
        return 0.0
    
    # Полный урон вблизи, уменьшение с расстоянием
    if distance <= max_damage_range:
        return damage
    
    # Линейное уменьшение урона
    var damage_reduction = (distance - max_damage_range) / (radius - max_damage_range)
    return damage * (1.0 - damage_reduction)

func inflict_damage(body: Node, damage_amount: float) -> void:
    if body.has_method("take_damage"):
        body.take_damage(damage_amount, damage_type, self)
    elif body.has_method("apply_damage"):
        body.apply_damage(damage_amount)

func _on_timer_timeout() -> void:
    apply_damage()

func _on_body_entered(body: Node) -> void:
    # Динамическое нанесение урона при входе в область
    if damage_applied and should_damage_body(body):
        var distance = global_position.distance_to(body.global_position)
        var calculated_damage = calculate_damage(distance)
        
        if calculated_damage > 0:
            inflict_damage(body, calculated_damage)

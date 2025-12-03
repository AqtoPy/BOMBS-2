extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D

var explosion_radius: float = 5.0
var base_damage: float = 50.0
var explosion_position: Vector3
var owner_node: Node

func setup(radius: float, damage: float, origin: Vector3, owner: Node) -> void:
    explosion_radius = radius
    base_damage = damage
    explosion_position = origin
    owner_node = owner
    
    # Настраиваем размер взрыва
    scale = Vector3.ONE * radius / 5.0
    if collision_shape:
        (collision_shape.shape as SphereShape3D).radius = radius

func _ready() -> void:
    particles.emitting = true
    apply_damage()
    
    # Удаляем после завершения эффектов
    await get_tree().create_timer(particles.lifetime).timeout
    queue_free()

func apply_damage() -> void:
    var area = $Area3D
    var bodies = area.get_overlapping_bodies()
    
    for body in bodies:
        if body == owner_node:
            continue
        
        if body.has_method("take_damage"):
            var damage = calculate_damage(body.global_position)
            if damage > 0:
                body.take_damage(damage)

func calculate_damage(target_position: Vector3) -> float:
    var distance = explosion_position.distance_to(target_position)
    
    if distance > explosion_radius:
        return 0.0
    
    # Проверяем укрытия
    var cover_factor = check_cover(explosion_position, target_position)
    
    # Рассчитываем урон (меньше с расстоянием)
    var distance_factor = 1.0 - (distance / explosion_radius)
    var final_damage = base_damage * distance_factor * cover_factor
    
    return final_damage

func check_cover(from: Vector3, to: Vector3) -> float:
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    
    # Исключаем самого владельца и эффекты взрыва
    query.exclude = [owner_node, self]
    
    # Настраиваем маски для проверки укрытий
    query.collision_mask = 0b1111  # Настройте под свои нужды
    
    var result = space_state.intersect_ray(query)
    
    if result:
        var collider = result.get("collider")
        
        # Проверяем слой укрытия (настройте в проекте)
        if collider.is_in_group("cover_heavy"):
            return 0.1  # 10% урона сквозь тяжелое укрытие
        elif collider.is_in_group("cover_medium"):
            return 0.3  # 30% урона сквозь среднее укрытие
        elif collider.is_in_group("cover_light"):
            return 0.6  # 60% урона сквозь легкое укрытие
    
    return 1.0  # Полный урон без укрытия

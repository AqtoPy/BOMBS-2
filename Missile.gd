extends Area3D

## Настройки ракеты
@export_category("Missile Settings")
@export var speed: float = 20.0
@export var gravity: float = 15.0
@export var explosion_radius: float = 5.0
@export var base_damage: float = 50.0
@export var max_lifetime: float = 10.0
@export var turn_speed: float = 5.0

## Сцены
@export var explosion_scene: PackedScene
@export var trail_particles: PackedScene

## Компоненты
@onready var ray_cast: RayCast3D = $RayCast3D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var mesh: MeshInstance3D = $MissileMesh

## Переменные
var velocity: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var has_exploded: bool = false
var owner_node: Node
var trail_instance: GPUParticles3D
var is_homing: bool = false

func _ready() -> void:
    # Настраиваем луч для обнаружения столкновений
    if ray_cast:
        ray_cast.enabled = true
    
    # Запускаем таймер времени жизни
    lifetime_timer.wait_time = max_lifetime
    lifetime_timer.start()
    
    # Создаем след
    if trail_particles:
        trail_instance = trail_particles.instantiate()
        add_child(trail_instance)
    
    # Подключаем сигналы
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)
    lifetime_timer.timeout.connect(_on_lifetime_timeout)

func setup(start_pos: Vector3, target_pos: Vector3, owner: Node, homing: bool = false) -> void:
    global_position = start_pos
    target_position = target_pos
    owner_node = owner
    is_homing = homing
    
    # Направление к цели
    var direction = (target_pos - start_pos).normalized()
    velocity = direction * speed
    
    # Добавляем вертикальную компоненту для дуги
    velocity.y = 5.0 if is_homing else 10.0
    
    # Направляем меш в сторону движения
    if velocity.length() > 0:
        look_at(global_position + velocity.normalized(), Vector3.UP)

func _physics_process(delta: float) -> void:
    if has_exploded:
        return
    
    # Обновляем цель для самонаведения
    if is_homing and is_instance_valid(owner_node):
        # Здесь можно добавить логику поиска цели
        pass
    
    # Применяем гравитацию
    velocity.y -= gravity * delta
    
    # Корректируем направление к цели (если нужно)
    if is_homing:
        adjust_direction(delta)
    
    # Движение
    global_position += velocity * delta
    
    # Поворачиваем меш в направлении движения
    if velocity.length() > 0.1:
        var target_direction = velocity.normalized()
        mesh.rotation.y = atan2(target_direction.x, target_direction.z)
        mesh.rotation.x = asin(-target_direction.y)
    
    # Проверяем столкновения через луч
    check_collision_with_ray()

func adjust_direction(delta: float) -> void:
    var direction_to_target = (target_position - global_position).normalized()
    velocity = velocity.lerp(direction_to_target * speed, turn_speed * delta)

func check_collision_with_ray() -> void:
    if not ray_cast or not ray_cast.is_colliding():
        return
    
    var collider = ray_cast.get_collider()
    var collision_point = ray_cast.get_collision_point()
    
    # Проверяем, не столкнулись ли с владельцем
    if collider == owner_node:
        return
    
    handle_collision(collision_point, collider)

func _on_body_entered(body: Node) -> void:
    if has_exploded or body == owner_node:
        return
    
    handle_collision(global_position, body)

func _on_area_entered(area: Area3D) -> void:
    if has_exploded:
        return
    
    handle_collision(global_position, area)

func handle_collision(position: Vector3, collider: Node) -> void:
    if has_exploded:
        return
    
    has_exploded = true
    
    # Создаем взрыв
    create_explosion(position)
    
    # Удаляем ракету
    queue_free()

func create_explosion(position: Vector3) -> void:
    if not explosion_scene:
        return
    
    var explosion = explosion_scene.instantiate()
    
    # Добавляем взрыв в сцену
    var root = get_tree().root.get_child(0)  # Получаем основную сцену
    if root:
        root.add_child(explosion)
        explosion.global_position = position
        
        # Передаем параметры взрыву
        if explosion.has_method("setup"):
            explosion.setup(explosion_radius, base_damage, position, owner_node)

func _on_lifetime_timeout() -> void:
    if not has_exploded:
        create_explosion(global_position)
        queue_free()

## Вспомогательные функции для поиска целей
func find_nearest_target() -> Node3D:
    var targets = get_tree().get_nodes_in_group("targets")
    var nearest_target = null
    var nearest_distance = INF
    
    for target in targets:
        if target == owner_node:
            continue
        
        var distance = global_position.distance_to(target.global_position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest_target = target
    
    return nearest_target

## Очистка
func _exit_tree() -> void:
    # Удаляем след при уничтожении ракеты
    if trail_instance and is_instance_valid(trail_instance):
        trail_instance.emitting = false
        trail_instance.queue_free()

extends Area3D

@export var speed: float = 20.0
@export var gravity: float = 9.8
@export var explosion_radius: float = 5.0
@export var base_damage: float = 50.0
@export var explosion_scene: PackedScene

var velocity: Vector3
var initial_position: Vector3
var has_exploded: bool = false
var owner_node: Node

func setup(start_pos: Vector3, target_pos: Vector3, owner: Node) -> void:
    global_position = start_pos
    initial_position = start_pos
    owner_node = owner
    
    # Направление к цели
    var direction = (target_pos - start_pos).normalized()
    velocity = direction * speed
    
    # Добавляем вертикальную компоненту для траектории
    velocity.y += 2.0

func _physics_process(delta: float) -> void:
    if has_exploded:
        return
    
    # Применяем гравитацию
    velocity.y -= gravity * delta
    
    # Движение
    var collision = move_and_collide(velocity * delta)
    
    if collision:
        var collider = collision.get_collider()
        handle_collision(collision.position, collider)

func handle_collision(position: Vector3, collider: Node) -> void:
    if has_exploded:
        return
    
    has_exploded = true
    
    # Создаем взрыв
    if explosion_scene:
        var explosion = explosion_scene.instantiate()
        get_parent().add_child(explosion)
        explosion.global_position = position
        explosion.setup(explosion_radius, base_damage, initial_position, owner_node)
    
    queue_free()

func _on_body_entered(body: Node) -> void:
    if body != owner_node and not has_exploded:
        handle_collision(global_position, body)

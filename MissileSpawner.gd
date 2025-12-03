extends Node3D

@export var missile_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var max_missiles: int = 10

var missiles_spawned: int = 0
var spawn_points: Array[Node3D] = []
var targets: Array[Node3D] = []

func _ready() -> void:
    # Находим точки спавна и цели
    for child in get_children():
        if child is Node3D:
            if "spawn_point" in child.name:
                spawn_points.append(child)
            elif "target" in child.name:
                targets.append(child)
    
    start_spawning()

func start_spawning() -> void:
    while missiles_spawned < max_missiles:
        spawn_missile()
        await get_tree().create_timer(spawn_interval).timeout

func spawn_missile() -> void:
    if missile_scene == null or spawn_points.is_empty() or targets.is_empty():
        return
    
    var spawn_point = spawn_points[randi() % spawn_points.size()]
    var target = targets[randi() % targets.size()]
    
    var missile = missile_scene.instantiate()
    get_parent().add_child(missile)
    missile.setup(spawn_point.global_position, target.global_position, self)
    
    missiles_spawned += 1

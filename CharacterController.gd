extends CharacterBody3D

## Настройки движения
@export_category("Movement Settings")
@export var max_speed: float = 10.0
@export var acceleration: float = 15.0
@export var deceleration: float = 25.0
@export var jump_force: float = 8.0
@export var air_control: float = 0.3

## Настройки камеры
@export_category("Camera Settings")
@export var mouse_sensitivity: float = 0.003
@export var camera_min_angle: float = -90.0
@export var camera_max_angle: float = 90.0
@export var camera_smoothing: float = 10.0

## Настройки игрока
@export_category("Player Settings")
@export var max_health: float = 100.0
@export var respawn_time: float = 3.0

## Компоненты
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var respawn_timer: Timer = $RespawnTimer
@onready var mesh: MeshInstance3D = $CharacterMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

## Переменные состояния
var current_health: float
var is_dead: bool = false
var can_move: bool = true
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity_y: float = 0.0
var current_camera_rotation: Vector2 = Vector2.ZERO
var target_camera_rotation: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Начальная настройка
	current_health = max_health
	update_health_ui()
	
	# Захват мыши
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Подписка на сигналы
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)

func _input(event: InputEvent) -> void:
	# Управление камерой мышью
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		handle_mouse_input(event)

func _physics_process(delta: float) -> void:
	if is_dead or not can_move:
		return
	
	# Обработка движения
	handle_movement(delta)
	
	# Плавное вращение камеры
	smooth_camera_rotation(delta)

func handle_mouse_input(event: InputEventMouseMotion) -> void:
	# Вращение по горизонтали (игрок)
	target_camera_rotation.x -= event.relative.x * mouse_sensitivity
	
	# Вращение по вертикали (камера)
	target_camera_rotation.y -= event.relative.y * mouse_sensitivity
	target_camera_rotation.y = clamp(target_camera_rotation.y, 
		deg_to_rad(camera_min_angle), deg_to_rad(camera_max_angle))

func smooth_camera_rotation(delta: float) -> void:
	# Интерполяция вращения камеры
	current_camera_rotation = current_camera_rotation.lerp(target_camera_rotation, camera_smoothing * delta)
	
	# Применяем вращение
	rotation.y = current_camera_rotation.x
	camera_pivot.rotation.x = current_camera_rotation.y

func handle_movement(delta: float) -> void:
	# Получаем вектор движения
	var input_vector = get_movement_input()
	
	# Преобразуем в мировые координаты
	var direction = (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	
	# Применяем гравитацию
	if is_on_floor():
		velocity_y = 0
		# Прыжок
		if Input.is_action_just_pressed("jump"):
			velocity_y = jump_force
	else:
		velocity_y -= gravity * delta
	
	# Управление скоростью
	var current_speed = velocity.length()
	var target_speed = 0.0
	
	if direction.length() > 0:
		target_speed = max_speed
		# Управление в воздухе
		if not is_on_floor():
			target_speed *= air_control
	
	# Интерполяция скорости
	if target_speed > 0:
		current_speed = lerp(current_speed, target_speed, acceleration * delta)
	else:
		current_speed = lerp(current_speed, 0.0, deceleration * delta)
	
	# Применяем скорость
	if direction.length() > 0:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)
	
	# Вертикальная скорость
	velocity.y = velocity_y
	
	# Движение
	move_and_slide()

func get_movement_input() -> Vector2:
	var input_vector = Vector2.ZERO
	
	# Собираем ввод
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	
	return input_vector.normalized()

## Система здоровья и урона
func take_damage(damage_amount: float, damage_source: Node = null) -> void:
	if is_dead:
		return
	
	# Уменьшаем здоровье
	current_health -= damage_amount
	current_health = max(current_health, 0)
	
	# Обновляем UI
	update_health_ui()
	
	# Эффект получения урона
	damage_effect()
	
	# Проверка смерти
	if current_health <= 0:
		die()

func heal(heal_amount: float) -> void:
	if is_dead:
		return
	
	current_health += heal_amount
	current_health = min(current_health, max_health)
	update_health_ui()

func update_health_ui() -> void:
	if health_bar:
		health_bar.value = (current_health / max_health) * 100

func damage_effect() -> void:
	# Визуальный эффект получения урона
	var material = mesh.get_surface_override_material(0)
	if material:
		material.albedo_color = Color.RED
		await get_tree().create_timer(0.1).timeout
		material.albedo_color = Color.WHITE

func die() -> void:
	is_dead = true
	can_move = false
	
	# Визуальный эффект смерти
	if mesh:
		mesh.visible = false
	
	# Отключаем коллизию
	if collision_shape:
		collision_shape.disabled = true
	
	print("Игрок умер!")
	
	# Запускаем таймер возрождения
	respawn_timer.start(respawn_time)

func respawn() -> void:
	# Сбрасываем здоровье
	current_health = max_health
	is_dead = false
	can_move = true
	
	# Восстанавливаем визуал
	if mesh:
		mesh.visible = true
	
	# Включаем коллизию
	if collision_shape:
		collision_shape.disabled = false
	
	# Обновляем UI
	update_health_ui()
	
	# Возвращаем на точку спавна
	# Здесь можно добавить логику для респавна на определенной точке
	global_position = Vector3(0, 1, 0)
	
	print("Игрок возродился!")

func _on_respawn_timer_timeout() -> void:
	if is_dead:
		respawn()

## Вспомогательные функции
func toggle_mouse_capture() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		can_move = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		can_move = true

func _unhandled_input(event: InputEvent) -> void:
	# Переключение захвата мыши по ESC
	if event.is_action_pressed("ui_cancel"):
		toggle_mouse_capture()
	
	# Перезагрузка игрока по R (для тестирования)
	if event.is_action_pressed("reload"):
		respawn()

## Сигналы для взаимодействия с другими объектами
func _on_hurtbox_area_entered(area: Area3D) -> void:
	# Пример: получение урона от взрыва
	if area.is_in_group("explosion"):
		var damage = area.get("damage_amount")
		if damage:
			take_damage(damage)

func _on_hurtbox_body_entered(body: Node) -> void:
	# Пример: получение урона при столкновении
	if body.is_in_group("enemy"):
		take_damage(10.0, body)

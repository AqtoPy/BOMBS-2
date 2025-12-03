extends Area3D

@export var player_node: NodePath

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area3D) -> void:
	var player = get_node(player_node)
	if player and player.has_method("take_damage"):
		# Получаем урон из области
		if area.has_method("get_damage"):
			var damage = area.get_damage()
			player.take_damage(damage, area.get_owner())

func _on_body_entered(body: Node) -> void:
	var player = get_node(player_node)
	if player and player.has_method("take_damage"):
		# Получаем урон от физического объекта
		if body.is_in_group("damaging"):
			player.take_damage(body.damage_amount, body)

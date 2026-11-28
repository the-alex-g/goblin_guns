class_name AmmoDump
extends Area2D

enum {AMMO, HEALTH}

@export var ammo := 10
@export var grenades := 2
@export var health := 2
@export var min_time := 10
@export var max_time := 30

var _mode := AMMO :
	set(value):
		_mode = value
		_sprite.play("ammo" if _mode == AMMO else "health")

@onready var _sprite := $AmmoDump


func _ready() -> void:
	_respawn()


func _respawn() -> void:
	_mode = AMMO if randf() < 0.75 else HEALTH
	show()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and visible:
		if _mode == AMMO:
			body.ammo += ammo
			body.grenades += grenades
		elif _mode == HEALTH:
			body.heal(health)
		hide()
		await get_tree().create_timer(randi_range(min_time, max_time)).timeout
		show()

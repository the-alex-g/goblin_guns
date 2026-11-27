class_name ExplosiveGrenade
extends Area2D

signal exploded(pos: Vector2)

const GRAVITY := 480.0

var velocity := Vector2.ZERO
var _disabled := false

@onready var _light : PointLight2D = $PointLight2D
@onready var _sprite : Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	if _disabled:
		return
	
	velocity.y += GRAVITY * delta
	position += velocity * delta


func _on_body_entered(_body: Node2D) -> void:
	if _disabled:
		return
	
	exploded.emit(global_position)
	_light.enabled = true
	_sprite.hide()
	_disabled = true
	await get_tree().create_tween().tween_property(_light, "energy", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).from_current().finished
	queue_free()

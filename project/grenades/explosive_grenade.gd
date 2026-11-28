class_name ExplosiveGrenade
extends Area2D

signal exploded(pos: Vector2)

const GRAVITY := 480.0

var velocity := Vector2.ZERO
var _disabled := false

@onready var _light : PointLight2D = $PointLight2D
@onready var _sprite : Sprite2D = $Sprite2D
@onready var _dump_destruction_zone : Area2D = $DumpDestructionZone


func _physics_process(delta: float) -> void:
	if _disabled:
		return
	
	velocity.y += GRAVITY * delta
	position += velocity * delta


func _destroy_ammo_dumps() -> void:
	for area in _dump_destruction_zone.get_overlapping_areas():
		if area is AmmoDump:
			area.queue_free()


func _on_body_entered(_body: Node2D) -> void:
	if _disabled:
		return
	
	exploded.emit(global_position)
	_light.enabled = true
	_sprite.hide()
	_disabled = true
	_destroy_ammo_dumps()
	await get_tree().create_tween().tween_property(_light, "energy", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).from_current().finished
	queue_free()

extends RigidBody2D

@export var fragment_speed := 100
@export var fragment_count := 12

@onready var _light : PointLight2D = $PointLight2D
@onready var _sprite := $Sprite2D


func _on_timer_timeout() -> void:
	for i : int in fragment_count:
		var angle := randf() * TAU
		var fragment : Fragment = preload("res://projectiles/fragment.tscn").instantiate()
		fragment.velocity = Vector2.from_angle(angle) * fragment_speed
		fragment.global_position = global_position
		get_parent().add_child(fragment)
	freeze = true
	_light.enabled = true
	_sprite.hide()
	await get_tree().create_tween().tween_property(_light, "energy", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).from_current().finished
	queue_free()

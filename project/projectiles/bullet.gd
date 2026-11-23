class_name Bullet
extends Area2D

var _damage := 2
var velocity := Vector2.ZERO


func _physics_process(delta: float) -> void:
	position += velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("hit"):
		body.hit(_damage)
	_damage -= 1
	if _damage <= 0:
		queue_free()

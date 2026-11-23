class_name Bullet
extends Node2D

const GRAVITY := 4.0

@export var cast_distance := 2.0
@export var damping := 0.9

var _damage := 2
@export var velocity := Vector2.ZERO

@onready var _vertical_raycast := $VertCast
@onready var _horizontal_raycast := $HorzCast


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY
	position += velocity * delta
	
	_vertical_raycast.target_position = Vector2.DOWN * signf(velocity.y) * cast_distance
	_horizontal_raycast.target_position = Vector2.RIGHT * signf(velocity.x) * cast_distance
	_vertical_raycast.force_raycast_update()
	_horizontal_raycast.force_raycast_update()
	
	if _vertical_raycast.is_colliding():
		velocity.y *= -1
		_bounce()
	elif _horizontal_raycast.is_colliding():
		velocity.x *= -1
		_bounce()


func _bounce() -> void:
	velocity *= damping
	_damage -= 1
	if _damage <= 0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("hit"):
		body.hit(_damage)

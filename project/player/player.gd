class_name Player
extends CharacterBody2D

const GRAVITY := 8.0

@export var speed := 80
@export var slide := Vector2(0.3, 0.1)
@export var jump_strength := 150
@export var bullet_speed := 320.0
@export var disabled = false
@export var index := 0

@onready var _sprite := $AnimatedSprite2D

func _physics_process(_delta:float)->void:
	if not is_on_floor() or velocity.y > 0.0:
		velocity.y += GRAVITY
	
	if not disabled:
		_process_actions()
	else:
		velocity.x = lerp(velocity.x, 0.0, slide.x)
	
	_process_animation()
	
	move_and_slide()
	
	position.x = fposmod(position.x, 160)


func _get_movement_axis() -> float:
	var axis := Input.get_joy_axis(index, JOY_AXIS_LEFT_X)
	if axis == 0 and index == 0:
		axis = Input.get_axis("left", "right")
	return axis


func _process_actions()->void:
	var axis := _get_movement_axis()
	var movement := (axis if abs(axis) > 0.25 else 0.0) * speed
	
	velocity.x = lerp(velocity.x, movement, slide.y)
	
	if Input.is_action_just_pressed("jump_%d" % index) and is_on_floor():
		velocity.y -= jump_strength
	if Input.is_action_just_pressed("fire_%d" % index):
		_fire_bullet()


func _process_animation()->void:
	if velocity.x < -0.1:
		_sprite.scale.x = -1.0
	elif velocity.x > 0.1:
		_sprite.scale.x = 1.0
	
	if abs(velocity.x) > 10.0:
		_sprite.play("run")
	else:
		_sprite.play("idle")


func _get_fire_angle() -> float:
	return roundf(get_angle_to(get_global_mouse_position()) * 8 / TAU) * TAU / 8


func _fire_bullet() -> void:
	var angle := _get_fire_angle()
	var bullet_velocity := Vector2.from_angle(angle) * bullet_speed
	var bullet : Bullet = preload("res://projectiles/bullet.tscn").instantiate()
	bullet.velocity = bullet_velocity
	bullet.global_position = global_position + Vector2.from_angle(angle) * 6 + Vector2.UP * 4
	get_tree().root.add_child(bullet)

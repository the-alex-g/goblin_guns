class_name Player
extends CharacterBody2D

const GRAVITY := 480.0

@export var disabled = false
@export var id := 0
@export_group("movement")
@export var speed := 100
@export var slide := Vector2(0.3, 0.1)
@export var jump_strength := 200
@export var anim_damping := 0.1
@export_group("combat")
@export var bullet_speed := 320.0
@export var grenade_speed := 200.0
@export var gun_cooldown := 0.25
@export var grenade_cooldown := 1.0

var _can_attack := true
var _health := 6 :
	set(value):
		_health = clampi(value, 0, 6)
		_healthbar.set_instance_shader_parameter("percent", value / 6.0)
var _special_animation_playing := false

@onready var _sprite := $AnimatedSprite2D
@onready var _healthbar := $HealthBar

func _physics_process(delta:float)->void:
	if not is_on_floor() or velocity.y > 0.0:
		velocity.y += GRAVITY * delta
	
	if not disabled:
		_process_actions()
	else:
		velocity.x = lerp(velocity.x, 0.0, slide.x)
	
	_process_animation()
	
	move_and_slide()
	
	position.x = fposmod(position.x, 160)


func _get_movement_axis() -> float:
	var axis := Input.get_joy_axis(id, JOY_AXIS_LEFT_X)
	if axis == 0 and id == 0:
		axis = Input.get_axis("left", "right")
	return axis


func _run_cooldown(time: float) -> void:
	_can_attack = false
	await get_tree().create_timer(time).timeout
	_can_attack = true


func _process_actions()->void:
	var axis := _get_movement_axis()
	var movement := (axis if abs(axis) > 0.25 else 0.0) * speed
	
	velocity.x = lerp(velocity.x, movement, slide.y)
	
	if Input.is_action_just_pressed("jump_%d" % id) and is_on_floor():
		velocity.y -= jump_strength
	if Input.is_action_just_pressed("fire_%d" % id) and _can_attack:
		_fire_bullet()
		_run_cooldown(gun_cooldown)
	if Input.is_action_just_pressed("frag_%d" % id) and _can_attack:
		_throw_grenade(preload("res://grenades/frag_grenade.tscn").instantiate())


func _is_aiming() -> bool:
	return true


func _get_facing() -> int:
	var dir : int = sign(velocity.x)
	return 2 if dir == 0 else dir * 2


func _process_animation()->void:
	if _special_animation_playing:
		return
	if _is_aiming():
		_play_shoot_animation(_get_fire_angle())
	else:
		if velocity.x < -anim_damping:
			_sprite.scale.x = -2.0
		elif velocity.x > anim_damping:
			_sprite.scale.x = 2.0
		if abs(velocity.x) > 10.0:
			_sprite.play("run")
		else:
			_sprite.play("idle")


func _get_fire_angle() -> float:
	return roundf(get_angle_to(get_global_mouse_position()) * 8 / TAU) * TAU / 8


func _get_launch_position(angle: float) -> Vector2:
	return global_position + Vector2.from_angle(angle) * 12 + Vector2.UP * 8


func _play_shoot_anim_by_name(base: String) -> void:
	_sprite.play("shoot_%s%s" % [base, "" if abs(velocity.x) < anim_damping else "_run"])


func _play_shoot_animation(angle: float) -> void:
	var index : int = round(angle * 4 / PI) + 4
	match index:
		0:
			_play_shoot_anim_by_name("level")
			_sprite.scale.x = -2
		1:
			_play_shoot_anim_by_name("slant_up")
			_sprite.scale.x = -2
		2:
			_play_shoot_anim_by_name("up")
			_sprite.scale.x = _get_facing()
		3:
			_play_shoot_anim_by_name("slant_up")
			_sprite.scale.x = 2
		4:
			_play_shoot_anim_by_name("level")
			_sprite.scale.x = 2
		5:
			_play_shoot_anim_by_name("slant_down")
			_sprite.scale.x = 2
		6:
			_play_shoot_anim_by_name("down")
			_sprite.scale.x = _get_facing()
		7:
			_play_shoot_anim_by_name("slant_down")
			_sprite.scale.x = -2


func _fire_bullet() -> void:
	var angle := _get_fire_angle()
	var bullet_velocity := Vector2.from_angle(angle) * bullet_speed
	var bullet : Bullet = preload("res://projectiles/bullet.tscn").instantiate()
	bullet.velocity = bullet_velocity
	bullet.global_position = _get_launch_position(angle)
	get_tree().root.add_child(bullet)


func _play_special_animation(anim_name: String) -> void:
	_sprite.play(anim_name)
	_special_animation_playing = true


func _throw_grenade(grenade: RigidBody2D) -> void:
	var angle := _get_fire_angle()
	grenade.global_position = _get_launch_position(angle)
	get_tree().root.add_child(grenade)
	grenade.apply_central_impulse(Vector2.from_angle(angle) * grenade_speed)
	_play_special_animation("throw_grenade")
	_run_cooldown(grenade_cooldown)


func hit(amount: int) -> void:
	_health -= amount


func _on_animated_sprite_2d_animation_finished() -> void:
	_special_animation_playing = false

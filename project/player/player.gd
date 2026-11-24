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
@export var gun_cooldown := 0.15
@export var grenade_cooldown := 0.75

var _can_attack := true
var _health := 6 :
	set(value):
		_health = clampi(value, 0, 6)
		_healthbar.set_instance_shader_parameter("percent", value / 6.0)
var _special_animation_playing := false
var _light_on := true

@onready var _sprite := $AnimatedSprite2D
@onready var _healthbar := $HealthBar
@onready var _light := $PointLight2D

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


func _is_action_pressed(action_name: String, button: JoyButton) -> bool:
	if id == 0 and Input.is_action_pressed(action_name):
		return true
	return Input.is_joy_button_pressed(id, button)


func _process_actions()->void:
	var axis := _get_movement_axis()
	var movement := (axis if abs(axis) > 0.25 else 0.0) * speed
	
	velocity.x = lerp(velocity.x, movement, slide.y)
	
	if _is_action_pressed("jump", JoyButton.JOY_BUTTON_A) and is_on_floor():
		velocity.y -= jump_strength
	if _is_action_pressed("fire", JoyButton.JOY_BUTTON_X) and _can_attack:
		_fire_bullet()
	if _is_action_pressed("frag", JoyButton.JOY_BUTTON_B) and _can_attack:
		_throw_grenade(preload("res://grenades/frag_grenade.tscn").instantiate())
	var sneaking := _is_action_pressed("sneak", JoyButton.JOY_BUTTON_PADDLE2)
	if sneaking and _light_on:
		_light_on = false
		get_tree().create_tween().tween_property(_light, "energy", 0.0, 0.25).from_current().set_trans(Tween.TRANS_QUAD)
	elif not sneaking and not _light_on:
		_light_on = true
		get_tree().create_tween().tween_property(_light, "energy", 1.0, 0.25).from_current().set_trans(Tween.TRANS_QUAD)


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


func _get_shoot_index(angle: float) -> int:
	return round(angle * 4 / PI) + 4


func _get_shoot_anim_name(angle: float) -> String:
	match _get_shoot_index(angle):
		0, 8:
			return "level"
		1:
			return "slant_up"
		2:
			return "up"
		3:
			return "slant_up"
		4:
			return "level"
		5:
			return "slant_down"
		6:
			return "down"
		7:
			return "slant_down"
	return ""


func _play_shoot_animation(angle: float) -> void:
	var anim_name := _get_shoot_anim_name(angle)
	var index : int = _get_shoot_index(angle)
	if anim_name != "":
		_play_shoot_anim_by_name(anim_name)
		if index <= 1 or index >= 7:
			_sprite.scale.x = -2
		elif index == 2 or index == 6:
			_sprite.scale.x = _get_facing()
		else:
			_sprite.scale.x = 2
	else:
		print("invalid index: %d" % index)


func _add_muzzle_flash(angle: float) -> void:
	var anim_name := _get_shoot_anim_name(angle)
	var flash := preload("res://player/muzzle_burst.tscn").instantiate()
	flash.global_position = global_position
	flash.anim_name = anim_name
	flash.scale.x = signi(_sprite.scale.x)
	get_tree().root.add_child(flash)


func _fire_bullet() -> void:
	var angle := _get_fire_angle()
	var bullet_velocity := Vector2.from_angle(angle) * bullet_speed
	var bullet : Bullet = preload("res://projectiles/bullet.tscn").instantiate()
	bullet.velocity = bullet_velocity
	bullet.global_position = _get_launch_position(angle)
	get_tree().root.add_child(bullet)
	_add_muzzle_flash(angle)
	_run_cooldown(gun_cooldown)


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

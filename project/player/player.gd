class_name Player
extends CharacterBody2D

signal died
signal weapon_fired(node: Node2D)

const GRAVITY := 480.0
const ANIM_NAMES : PackedStringArray = ["level", "slant_up", "up", "slant_up", "level", "slant_down", "down", "slant_down", "level"]

@export var disabled := false
@export var id := 0
@export var mouse_aim := false :
	get:
		return mouse_aim and id == 0
@export var infinite_ammo := false
@export_group("movement")
@export var speed := 100
@export var slide := Vector2(0.3, 0.1)
@export var jump_strength := 200
@export var anim_damping := 10.0
@export_group("combat")
@export var bullet_speed := 320.0
@export var grenade_speed := 200.0
@export var gun_cooldown := 0.15
@export var grenade_cooldown := 0.75
@export var knockback := 5.0
@export var ammo := 20 :
	set(value):
		ammo = max(0, value)
		_ammo_warning.visible = ammo == 0 and not infinite_ammo
@export var grenades := 5 :
	set(value):
		grenades = max(0, value)
		_grenade_warning.visible = grenades == 0 and not infinite_ammo

var _can_attack := true
var _health := 6 :
	set(value):
		if value <= 0:
			_die()
		_health = clampi(value, 0, 6)
		_healthbar.set_instance_shader_parameter("percent", value / 6.0)
var _special_animation_playing := false
var _light_on := true
var _aim_angle := 0.0

@onready var _sprite := $AnimatedSprite2D
@onready var _healthbar := $HealthBar
@onready var _light : PointLight2D = $PointLight2D
@onready var _collision_shape : CollisionShape2D = $CollisionShape2D
@onready var _wall_detector : RayCast2D = $WallDetector
@onready var _ammo_warning : Sprite2D = $AmmoWarning
@onready var _grenade_warning : Sprite2D = $GrenadeWarning

func _physics_process(delta:float)->void:
	if not is_on_floor() or velocity.y > 0.0:
		velocity.y += GRAVITY * delta
	
	if not disabled:
		_process_actions()
	else:
		velocity.x = lerp(velocity.x, 0.0, slide.x)
	
	_update_aim_angle()
	
	if not _special_animation_playing:
		_play_shoot_animation()
	
	move_and_slide()
	queue_redraw()


func _die() -> void:
	if not disabled:
		disabled = true
		_light.enabled = false
		_collision_shape.set_deferred("disabled", true)
		hide()
		died.emit()


func respawn(pos: Vector2) -> void:
	print("player %d respawning at %v" % [id, pos])
	_health = 6
	disabled = false
	_light.enabled = true
	global_position = pos
	_collision_shape.disabled = false
	show()


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


func _is_axis_action_pressed(action_name: String, axis: JoyAxis) -> bool:
	return (id == 0 and Input.is_action_pressed(action_name)) or Input.get_joy_axis(id, axis) > 0.5


func _process_actions()->void:
	var axis := _get_movement_axis()
	var movement := (axis if abs(axis) > 0.25 else 0.0) * speed
	
	velocity.x = lerp(velocity.x, movement, slide.y)
	
	if _is_action_pressed("jump", JoyButton.JOY_BUTTON_A) and is_on_floor():
		velocity.y -= jump_strength
	if _is_action_pressed("fire", JoyButton.JOY_BUTTON_LEFT_SHOULDER) and _can_attack and (ammo > 0 or infinite_ammo):
		_fire_bullet()
	if _is_action_pressed("frag", JoyButton.JOY_BUTTON_RIGHT_SHOULDER) and _can_attack and (grenades > 0 or infinite_ammo):
		_throw_grenade(preload("res://grenades/frag_grenade.tscn").instantiate())
	var sneaking := _is_axis_action_pressed("sneak", JoyAxis.JOY_AXIS_TRIGGER_LEFT)
	if sneaking and _light_on:
		_light_on = false
		get_tree().create_tween().tween_property(_light, "energy", 0.0, 0.25).from_current().set_trans(Tween.TRANS_QUAD)
	elif not sneaking and not _light_on:
		_light_on = true
		get_tree().create_tween().tween_property(_light, "energy", 1.0, 0.25).from_current().set_trans(Tween.TRANS_QUAD)


func _get_controller_aim() -> Vector2:
	var x_axis := Input.get_joy_axis(id, JOY_AXIS_RIGHT_X)
	var y_axis := Input.get_joy_axis(id, JOY_AXIS_RIGHT_Y)
	return Vector2(
		x_axis if abs(x_axis) > 0.4 else 0.0,
		y_axis if abs(y_axis) > 0.4 else 0.0
	)


func _get_facing() -> int:
	var dir : int = sign(velocity.x)
	return 2 if dir == 0 else dir * 2


func _clamp_angle(angle: float) -> float:
	return roundf(angle * 8 / TAU) * TAU / 8


func _update_aim_angle() -> void:
	var controller_aim := _get_controller_aim()
	if controller_aim == Vector2.ZERO and mouse_aim:
		_aim_angle = _clamp_angle(get_angle_to(get_global_mouse_position()))
	elif controller_aim != Vector2.ZERO:
		_aim_angle = _clamp_angle(controller_aim.angle())


func _get_launch_position(no_obstruction := false) -> Vector2:
	var offset := Vector2.from_angle(_aim_angle) * 12
	if no_obstruction:
		_wall_detector.target_position = offset
		_wall_detector.force_raycast_update()
		if _wall_detector.is_colliding():
			return Vector2.INF
	return offset + global_position + Vector2.UP * 8


func _play_shoot_anim_by_name(base: String) -> void:
	_sprite.play("shoot_%s%s" % [base, "" if abs(velocity.x) < anim_damping else "_run"])


func _get_shoot_index() -> int:
	return round(_aim_angle * 4 / PI) + 4


func _get_shoot_anim_name() -> String:
	var index := _get_shoot_index()
	if index >= 0 and index <= 8:
		return ANIM_NAMES[index]
	return ""


func _play_shoot_animation() -> void:
	var anim_name := _get_shoot_anim_name()
	var index : int = _get_shoot_index()
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


func _add_muzzle_flash() -> void:
	var anim_name := _get_shoot_anim_name()
	var flash := preload("res://player/muzzle_burst.tscn").instantiate()
	flash.global_position = global_position
	flash.anim_name = anim_name
	flash.scale.x = signi(_sprite.scale.x)
	get_tree().root.add_child(flash)


func _fire_bullet() -> void:
	var bullet_velocity := Vector2.from_angle(_aim_angle) * bullet_speed
	var bullet : Bullet = preload("res://projectiles/bullet.tscn").instantiate()
	bullet.velocity = bullet_velocity
	bullet.global_position = _get_launch_position()
	weapon_fired.emit(bullet)
	_add_muzzle_flash()
	_run_cooldown(gun_cooldown)
	velocity -= Vector2.from_angle(_aim_angle) * knockback
	ammo -= 1


func _play_special_animation(anim_name: String) -> void:
	_sprite.play(anim_name)
	_special_animation_playing = true


func _throw_grenade(grenade: RigidBody2D) -> void:
	var pos := _get_launch_position(true)
	if pos != Vector2.INF:
		grenade.global_position = pos
		weapon_fired.emit(grenade)
		grenade.apply_central_impulse(Vector2.from_angle(_aim_angle) * grenade_speed)
		_play_special_animation("throw_grenade")
		_run_cooldown(grenade_cooldown)
		grenades -= 1


func hit(amount: int) -> void:
	_health -= amount


func _on_animated_sprite_2d_animation_finished() -> void:
	_special_animation_playing = false

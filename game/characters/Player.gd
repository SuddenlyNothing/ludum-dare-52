extends KinematicBody2D
class_name BasicPlatformer
# warnings-disable

signal threw

var jump_height: float = 85.0
var jump_time_to_peak: float = 0.25
var jump_time_to_descent: float = 0.27

var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * \
		jump_time_to_peak)) * -1.0
var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_descent * \
		jump_time_to_descent)) * -1.0

var max_move_speed: float = 230
var max_fall_speed: float = fall_gravity * jump_time_to_descent

var acceleration_time: float = 0.05
var turn_acceleration_time: float = 0.08
var air_friction_time: float = 0.2
var ground_friction_time: float = 0.07

var acceleration: float = max_move_speed / acceleration_time
var turn_acceleration: float = max_move_speed / turn_acceleration_time
var air_friction: float = max_move_speed / air_friction_time
var ground_friction: float = max_move_speed / ground_friction_time

var max_climb_speed: float = 150
var climb_acceleration_time: float = 0.1
var climb_acceleration: float = max_climb_speed / climb_acceleration_time
var climb_friction_time: float = 0.03
var climb_friction: float = max_climb_speed / climb_friction_time
var climb_jump_force: float = max_move_speed
var climb_ledge_force: float = 170

var attack_speed: float = 400.0
var attack_hit_speed: float = 1000.0

var hurt_speed: float = 100
var hurt_height: float = 60.0
var hurt_fall_time: float = 0.25
var hurt_jump_speed: float = ((2.0 * hurt_height) / hurt_fall_time) * -1.0
var hurt_gravity: float = ((-2.0 * jump_height) / (jump_time_to_descent * \
		jump_time_to_descent)) * -1.0

var x_input := 0
var prev_x_input := 1
var y_input := 0
var max_air_jumps := 1
var air_jumps := max_air_jumps
var velocity := Vector2()

var snap := Vector2.DOWN * 0.5
var up := Vector2.UP
var stopped_jump := false
var wall_dir := Vector2.RIGHT
var attacked := false
var attack_animation_finished := false
var attack_animation_follow_through_finished := false
var passed_through_hittables := false
var attacking := false
var attacked_hittables := {}

var hurt_dir := 1

var max_health := 6
var health := max_health

var queue_animation := "idle"
var hittables := {}

onready var flip := $Flip
onready var anim_sprite := $Flip/AnimatedSprite
onready var coyote_timer := $CoyoteTimer
onready var jump_buffer_timer := $JumpBufferTimer
onready var wall_jump_timer := $WallJumpTimer
onready var save_jump_casts := $SaveJumpCasts
onready var prevent_cling_cast := $PreventClingCast
onready var wall_cling_stay_timer := $WallClingStayTimer
onready var hurt_timer := $HurtTimer
onready var attack_delay_timer := $AttackDelayTimer
onready var player_states := $PlayerStates
onready var i_timer := $ITimer
onready var i_flash_timer := $IFlashTimer
onready var hitbox_collision := $Flip/Hitbox/CollisionShape2D
onready var hurtbox_collision := $Hurtbox/CollisionShape2D
onready var hud := $PlayerHUD

onready var attack_sfx := $Audio/AttackSFX
onready var death_sfx := $Audio/DeathSFX
onready var hurt_sfx := $Audio/HurtSFX
onready var jump_sfx := $Audio/JumpSFX
onready var land_sfx := $Audio/LandSFX
onready var step_sfx := $Audio/StepSFX
onready var throw_sfx := $Audio/ThrowSFX
onready var cling_sfx := $Audio/ClingSFX
onready var wall_jump_sfx := $Audio/WallJumpSFX
onready var wall_move_sfx := $Audio/WallMoveSFX


func _process(delta: float) -> void:
	set_x_input()
	set_y_input()
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()


func hit(dir: int) -> void:
	if not i_timer.is_stopped():
		return
	health -= 1
	hud.set_health(float(health) / max_health)
	
	if health > 0:
		var t := create_tween()
		t.tween_property(anim_sprite.get_material(), "shader_param/hit_strength",
				0.0, 0.5).from(1.0)
		set_collisions_disabled(true)
		i_flash_timer.start()
		i_timer.start()
		hurt_dir = dir
		player_states.call_deferred("set_state", "hurt")
	else:
		player_states.call_deferred("set_state", "death")


func throw(dir: int) -> void:
	if sign(dir) != sign(flip.scale.x):
		flip.scale.x *= -1
	player_states.call_deferred("set_state", "throw")
	throw_sfx.play()


func set_collisions_disabled(disabled: bool) -> void:
#	hitbox_collision.call_deferred("set_disabled", disabled)
	hurtbox_collision.call_deferred("set_disabled", disabled)


func move(delta: float, is_on_ground: bool, is_falling: bool) -> void:
	apply_acceleration(delta)
	apply_velocity(delta, is_on_ground)
	apply_friction(delta, is_on_ground)
	apply_gravity(delta, is_falling)


func can_jump(is_on_ground: bool) -> bool:
	if is_on_ground:
		if not jump_buffer_timer.is_stopped():
			return true
	else:
		if not jump_buffer_timer.is_stopped():
			if not coyote_timer.is_stopped():
				return true
			elif air_jumps > 0 and not can_save_jump():
				air_jumps -= 1
				return true
	return false


func can_attack() -> bool:
	return not attacked and Input.is_action_pressed("attack") and \
			attack_delay_timer.is_stopped()


func can_save_jump() -> bool:
	var collisions := 0
	for cast in save_jump_casts.get_children():
		if cast.is_colliding():
			collisions += 1
	return collisions >= 2


func reset_air_jumps() -> void:
	air_jumps = max_air_jumps


func set_facing() -> void:
	if x_input > 0 and flip.scale.x < 0:
		flip.scale.x *= -1
	elif x_input < 0 and flip.scale.x > 0:
		flip.scale.x *= -1


func set_y_input() -> void:
	y_input = Input.get_action_strength("down") - \
			Input.get_action_strength("up")


func set_x_input() -> void:
	if not wall_jump_timer.is_stopped():
		x_input = 0
		return
	x_input = Input.get_action_strength("right") - \
			Input.get_action_strength("left")
	if x_input:
		prev_x_input = x_input


func set_attack_velocity() -> void:
	velocity = Vector2(prev_x_input, 0) * attack_speed
	if prev_x_input > 0 and flip.scale.x < 0:
		flip.scale.x *= -1
	elif prev_x_input < 0 and flip.scale.x > 0:
		flip.scale.x *= -1


func set_hurt_velocity() -> void:
	velocity = Vector2(hurt_dir * hurt_speed, hurt_jump_speed)


func apply_acceleration(delta: float) -> void:
	if sign(x_input) == sign(velocity.x) or velocity.x == 0:
		velocity.x = clamp(velocity.x + acceleration * x_input * delta,
				-max_move_speed, max_move_speed)
	else:
		velocity.x = clamp(velocity.x + turn_acceleration * x_input * delta,
				-max_move_speed, max_move_speed)


func apply_friction(delta: float, is_on_ground: bool) -> void:
	if x_input != 0 or not wall_jump_timer.is_stopped():
		return
	var friction := 0.0
	if is_on_ground:
		friction = ground_friction
	else:
		friction = air_friction
	var friction_amount := friction * delta
	if abs(velocity.x) <= friction_amount / 2.0:
		velocity.x = 0
	elif velocity.x > 0:
		velocity.x -= friction_amount
	else:
		velocity.x += friction_amount


func apply_velocity(delta: float, is_on_ground: bool) -> void:
	if is_on_ground:
		velocity = move_and_slide_with_snap(velocity, snap, up)
	else:
		velocity = move_and_slide(velocity, up)


func apply_gravity(delta: float, is_falling: bool) -> void:
	if is_falling:
		velocity.y = min(velocity.y + fall_gravity * delta, max_fall_speed)
	else:
		velocity.y = min(velocity.y + jump_gravity * delta, max_fall_speed)


func can_cling() -> bool:
	return is_on_wall() and not prevent_cling_cast.is_colliding() and \
			x_input != 0


func set_wall_dir() -> void:
	var closest_dot := 2.0
	var closest_normal := Vector2()
	for i in get_slide_count():
		var normal := get_slide_collision(i).normal
		var dot = Vector2.UP.dot(normal)
		if dot < closest_dot:
			closest_normal = normal
			closest_dot = dot
	wall_dir = closest_normal


func apply_wall_friction(delta: float) -> void:
	if y_input:
		return
	if velocity.y < 0:
		apply_gravity(delta, false)
		return
	var friction_amount := climb_friction * delta
	if friction_amount >= velocity.length():
		velocity = Vector2()
	else:
		velocity -= velocity.normalized() * friction_amount


func apply_wall_acceleration(delta: float) -> void:
	if not y_input:
		return
	if y_input > 0 and velocity.y > max_climb_speed:
		return
	if not wall_move_sfx.playing:
		wall_move_sfx.play()
	velocity.y = clamp(velocity.y + climb_acceleration * y_input * delta,
			-max_climb_speed, max_climb_speed)


func wall_move(delta: float) -> void:
	apply_wall_acceleration(delta)
	apply_wall_friction(delta)
	velocity = move_and_slide_with_snap(velocity - wall_dir,
			-wall_dir * 0.5, wall_dir)


func attack_move(delta: float) -> void:
	if hittables.empty() or attack_animation_finished:
		velocity = velocity.normalized() * attack_speed
	else:
		velocity = velocity.normalized() * attack_hit_speed
	velocity = move_and_slide(velocity, up)
	if is_on_wall():
		attack_animation_follow_through_finished = true
#	if is_on_wall():
#		var closest_dot := 2.0
#		var closest_normal := Vector2()
#		for i in get_slide_count():
#			var normal := get_slide_collision(i).normal
#			var dot = Vector2.UP.dot(normal)
#			if dot < closest_dot:
#				closest_normal = normal
#				closest_dot = dot
#		hurt_dir = sign(closest_normal.x)


func death_move(delta: float) -> void:
	apply_gravity(delta, true)
	var friction_amount := ground_friction * delta
	if abs(velocity.x) <= friction_amount / 2.0:
		velocity.x = 0
	elif velocity.x > 0:
		velocity.x -= friction_amount
	else:
		velocity.x += friction_amount
	apply_velocity(delta, false)


func finished_attack() -> bool:
	return attack_animation_finished and hittables.empty()


func add_hittables() -> void:
	for hittable in hittables:
		hittable.hit(sign(velocity.x))
		attacked_hittables[hittable] = 1


func attack() -> void:
	for hittable in attacked_hittables:
		hittable.hit(sign(velocity.x))
	attacked_hittables.clear()


func apply_hurt_gravity(delta: float) -> void:
	velocity.y = min(velocity.y + hurt_gravity * delta, max_fall_speed)


func hurt_move(delta: float) -> void:
	apply_hurt_gravity(delta)
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.normal) * 0.9


func jump() -> void:
	velocity.y = jump_velocity
	stopped_jump = false
	coyote_timer.stop()
	jump_buffer_timer.stop()
	if not Input.is_action_pressed("jump"):
		stop_jump()


func wall_jump() -> void:
	velocity.x = climb_jump_force * sign(wall_dir.x)
	wall_jump_timer.start()


func climb_ledge() -> void:
	velocity.x = sign(-wall_dir.x) * climb_ledge_force


func can_stop_cling() -> bool:
	var is_at_ground: bool = prevent_cling_cast.is_colliding()
	if wall_dir.x > 0:
		if Input.is_action_pressed("right"):
			if is_at_ground:
				return true
		else:
			wall_cling_stay_timer.start()
	else:
		if Input.is_action_pressed("left"):
			if is_at_ground:
				return true
		else:
			wall_cling_stay_timer.start()
	return wall_cling_stay_timer.is_stopped()


func stop_jump() -> void:
	if stopped_jump:
		return
	stopped_jump = true
	velocity.y /= 2


func play_anim(anim : String) -> void:
	if anim == "jump" and anim_sprite.animation == anim:
		anim_sprite.frame = 1
	if anim == "fall":
		anim_sprite.animation = "jump"
		anim_sprite.frame = 4
		return
	if anim_sprite.animation == "land" and (anim == "idle" or anim == "walk"):
		queue_animation = anim
		return
	anim_sprite.play(anim)


func _on_AnimatedSprite_animation_finished() -> void:
	if anim_sprite.animation == "land":
		anim_sprite.play(queue_animation)
	if anim_sprite.animation == "attack":
		attack_animation_finished = true
		attacking = false
	if anim_sprite.animation == "attack_finish" and hittables.empty():
		attack_animation_follow_through_finished = true
	if anim_sprite.animation == "throw":
		player_states.call_deferred("set_state", "fall")


func _on_AnimatedSprite_frame_changed() -> void:
	if anim_sprite.animation == "land" and queue_animation == "walk" and \
			anim_sprite.frame >= 1:
		anim_sprite.play(queue_animation)
	if anim_sprite.animation == "walk":
		if anim_sprite.frame == 1 or anim_sprite.frame == 2:
			step_sfx.play()
	if anim_sprite.animation == "throw" and anim_sprite.frame == 2:
		emit_signal("threw")


func _on_Hitbox_body_entered(body: Node) -> void:
	if not body.is_in_group("hittable"):
		return
	if attacking:
		body.hit(sign(velocity.x))
		attacked_hittables[body] = 1
	hittables[body] = 0


func _on_Hitbox_body_exited(body: Node) -> void:
	if not body.is_in_group("hittable"):
		return
	hittables.erase(body)


func _on_ITimer_timeout() -> void:
	set_collisions_disabled(false)
	i_flash_timer.stop()
	anim_sprite.show()


func _on_IFlashTimer_timeout() -> void:
	anim_sprite.visible = not anim_sprite.visible

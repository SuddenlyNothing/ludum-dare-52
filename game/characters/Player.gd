extends KinematicBody2D
class_name BasicPlatformer
# warnings-disable

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
var climb_friction_time: float = 0.1
var climb_friction: float = max_climb_speed / climb_friction_time
var climb_jump_force: float = 1000
#var climb_jump_friction_time: float = 2.0
#var climb_jump_friction: float = climb_jump_force / climb_jump_friction_time

var climb_ledge_force: float = 1000

var x_input := 0
var y_input := 0
var max_air_jumps := 1
var air_jumps := max_air_jumps
var velocity := Vector2()

var snap := Vector2.DOWN * 0.5
var up := Vector2.UP
var stopped_jump := false
var wall_dir := Vector2.RIGHT

var queue_animation := "idle"

onready var flip := $Flip
onready var anim_sprite := $Flip/AnimatedSprite
onready var coyote_timer := $CoyoteTimer
onready var jump_buffer_timer := $JumpBufferTimer
onready var wall_jump_timer := $WallJumpTimer
onready var save_jump_casts := $SaveJumpCasts
onready var prevent_cling_cast := $PreventClingCast
onready var wall_cling_stay_timer := $WallClingStayTimer


#func _ready() -> void:
#	Engine.time_scale = 0.3


func _process(delta: float) -> void:
	set_x_input()
	set_y_input()
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()


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
	return is_on_wall() and not prevent_cling_cast.is_colliding()


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
	velocity.y = clamp(velocity.y + climb_acceleration * y_input * delta,
			-max_climb_speed, max_climb_speed)


func wall_move(delta: float) -> void:
	apply_wall_acceleration(delta)
	apply_wall_friction(delta)
	velocity = move_and_slide_with_snap(velocity - wall_dir,
			-wall_dir * 0.5, wall_dir)


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


func _on_AnimatedSprite_frame_changed() -> void:
	if anim_sprite.animation == "land" and queue_animation == "walk" and \
			anim_sprite.frame >= 1:
		anim_sprite.play(queue_animation)

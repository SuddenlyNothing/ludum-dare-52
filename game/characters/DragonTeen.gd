extends KinematicBody2D

signal died(angered)
signal downed
signal hit(percent)

const Fireball := preload("res://characters/Fireball.tscn")

var target: Node2D

var speed := 400
var swiping_speed := 200
var in_range := false
var idle_velocity := Vector2()
var flap_force := 300
var idle_friction := 1000
var fed := false
var angered := false
var landed := false

var fireballs := 3
var fireball_count := fireballs

var knockouts_remaining := 2
var max_health := 3
var health = max_health
var total_health := knockouts_remaining * max_health + max_health

var gravity := 1000.0
var fall_velocity := Vector2()

var died := false

onready var anim_sprite := $Pivot/DragonTeenAnimations
onready var states := $DragonTeenStates
onready var swipe_pos := $Pivot/SwipePos
onready var hitbox := $Pivot/Hitbox
onready var pivot := $Pivot
onready var idle_wait_timer := $IdleWaitTimer
onready var fireball_pos := $Pivot/FireballPos
onready var mouth_pos := $Pivot/MouthPos

onready var death_sfx := $DeathSFX
onready var fireball_sfx := $FireballSFX
onready var flap_sfx := $FlapSFX
onready var hurt_sfx := $HurtSFX
onready var down_sfx := $DownSFX
onready var land_sfx := $LandSFX
onready var swipe_sfx := $SwipeSFX
onready var evolve_sfx := $EvolveSFX


func _ready() -> void:
	target = get_tree().get_nodes_in_group("player")[0]


func feed() -> void:
	fed = true
	anim_sprite.play("eat")


func wake() -> void:
	angered = true
	states.call_deferred("set_state", "idle")


func move_fall(delta: float) -> void:
	fall_velocity.y += gravity * delta
	move_and_slide(fall_velocity)


func move_down(delta: float) -> void:
	if landed:
		return
	move_fall(delta)
	if get_slide_count():
		landed = true
		land_sfx.play()
		anim_sprite.play("down")
		emit_signal("downed")


func move_death(delta: float) -> void:
	if landed:
		return
	move_fall(delta)
	if get_slide_count():
		landed = true
		land_sfx.play()
		anim_sprite.play("death")


func hit(dir: int) -> void:
	if died:
		return
	var t := create_tween()
	t.tween_property(anim_sprite.get_material(), "shader_param/hit_strength",
			0.0, 0.5).from(1.0)
	
	health -= 1
	emit_signal("hit", float(knockouts_remaining * max_health + health) / \
			total_health)
	if health <= 0:
		if knockouts_remaining > 0:
			if not angered:
				states.call_deferred("set_state", "down")
			health = max_health
			knockouts_remaining -= 1
			down_sfx.play()
		else:
			states.call_deferred("set_state", "death")
			death_sfx.play()
			died = true
	else:
		hurt_sfx.play()
		if not fed and states.state == "down":
			angered = true


func set_collision_bit(on: bool) -> void:
	set_collision_mask_bit(0, on)


func play_anim(anim: String) -> void:
	anim_sprite.play(anim)


func move_swipe(delta: float) -> void:
	set_facing()
	if swipe_pos.global_position.distance_squared_to(target.position) < 20:
		anim_sprite.play("swipe")
	elif anim_sprite.animation != "swipe":
		position += swipe_pos.global_position.direction_to(target.position) * \
				speed * delta
	else:
		position += swipe_pos.global_position.direction_to(target.position) * \
				swiping_speed * delta


func move_idle(delta: float) -> void:
	var friction_amount = idle_friction * delta
	if idle_velocity.length() <= friction_amount:
		idle_velocity = Vector2()
	else:
		idle_velocity -= idle_velocity.normalized() * friction_amount
	move_and_slide(idle_velocity)


func set_facing() -> void:
	if (pivot.scale.x < 0 and target.position.x < position.x) or \
			(pivot.scale.x > 0 and target.position.x > position.x):
		pivot.scale.x *= -1


func _on_DragonTeenAnimations_animation_finished() -> void:
	if anim_sprite.animation == "evolve":
		states.call_deferred("set_state", "idle")
	if anim_sprite.animation == "swipe":
		anim_sprite.play("swipe_end")
	if anim_sprite.animation == "swipe_end":
		states.call_deferred("set_state", "idle")
	if anim_sprite.animation == "fireball":
		set_facing()
		fireball_count -= 1
		if fireball_count <= 0:
			states.call_deferred("set_state", "swipe")
	if anim_sprite.animation == "eat":
		states.call_deferred("set_state", "idle")
	if anim_sprite.animation == "death":
		emit_signal("died", angered)



func _on_DragonTeenAnimations_frame_changed() -> void:
	if anim_sprite.animation == "swipe":
		if anim_sprite.frame == 5:
			for body in hitbox.get_overlapping_bodies():
				if body.is_in_group("player"):
					body.hit(-pivot.scale.x)
			swipe_sfx.play()
	if anim_sprite.animation == "idle":
		if anim_sprite.frame == 2:
			idle_velocity += Vector2(sign(position.x - target.position.x),
					-1).normalized() * flap_force
			flap_sfx.play()
	if anim_sprite.animation == "fireball":
		if anim_sprite.frame == 4:
			var fireball := Fireball.instance()
			fireball.position = fireball_pos.global_position
			fireball.dir = fireball_pos.global_position.direction_to(
				target.position).rotated((randf() - 0.5) * PI / 8)
			get_parent().add_child(fireball)
			fireball_sfx.play()
	if anim_sprite.animation == "evolve":
		if anim_sprite.frame == 5:
			evolve_sfx.play()

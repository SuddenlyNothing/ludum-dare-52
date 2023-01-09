extends KinematicBody2D

var velocity := Vector2()

var stop_dist := 20
var charge_speed := 300.0
var friction: float = (charge_speed * charge_speed) / (stop_dist * 2)
var charge_dir := -1
var snap := Vector2.DOWN * 12
var charging := false

onready var anim_sprite := $Pivot/DragonBabyAnimations
onready var charge_wait_timer := $ChargeWaitTimer
onready var raycast := $Pivot/RayCast2D
onready var pivot := $Pivot
onready var hitbox_collision := $Pivot/Hitbox/CollisionShape2D

onready var charge_sfx := $ChargeSFX
onready var death_sfx := $DeathSFX
onready var hurt_sfx := $HurtSFX
onready var down_sfx := $DownSFX


func flip() -> void:
	pivot.scale.x *= -1
	charge_dir *= -1


func set_charge_velocity() -> void:
	velocity = Vector2(charge_dir * charge_speed, 0)


func apply_charge_friction(delta: float) -> void:
	var friction_amount = friction * delta
	if friction_amount >= abs(velocity.x):
		velocity = Vector2()
	else:
		velocity.x -= sign(velocity.x) * friction_amount


func move_charge(delta: float) -> void:
	if not charging:
		return
	if raycast.is_colliding():
		apply_charge_friction(delta)
	move_and_slide_with_snap(velocity, snap)


func play_anim(anim: String) -> void:
	anim_sprite.play(anim)


func hit(dir: int) -> void:
	hurt_sfx.play()
	var t := create_tween()
	t.tween_property(anim_sprite.get_material(), "shader_param/hit_strength",
			0.0, 0.5).from(1.0)


func set_hitbox_disabled(disabled: bool) -> void:
	hitbox_collision.call_deferred("set_disabled", disabled)


func _on_DragonBabyAnimations_animation_finished() -> void:
	if anim_sprite.animation == "charge_prep":
		charging = true
		charge_sfx.play()
		anim_sprite.play("charge")
		set_hitbox_disabled(false)


func _on_Hitbox_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.hit(charge_dir)

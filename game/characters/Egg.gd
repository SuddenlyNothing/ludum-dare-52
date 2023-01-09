extends KinematicBody2D

signal hit
signal downed
signal died(angered)

var hit := false

onready var collision := $CollisionShape2D
onready var anim_sprite := $AnimatedSprite


func _ready() -> void:
	anim_sprite.play("wiggle")


func hit(dir: int) -> void:
	if hit:
		return
	hit = true
	emit_signal("died", false)
	collision.call_deferred("set_disabled", true)
	anim_sprite.play("hatch")


func _on_AnimatedSprite_animation_finished() -> void:
	if anim_sprite.animation == "hatch":
		anim_sprite.play("idle")

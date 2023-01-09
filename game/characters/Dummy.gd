extends KinematicBody2D

onready var anim_sprite := $PlayerAnimations


func hit() -> void:
	var t := create_tween()
	t.tween_property(anim_sprite.get_material(), "shader_param/hit_strength",
			0.0, 0.3).from(1.0)

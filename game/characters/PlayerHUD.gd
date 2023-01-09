extends CanvasLayer

var t: SceneTreeTween

onready var health_bar := $Control/HealthBar
onready var anim_sprite := $Control/HealthBar/AnimatedSprite


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	health_bar.rect_position = Vector2((randf() - 0.5) * 5, (randf() - 0.5) * 5)


func set_health(percent: float) -> void:
	if percent > 0:
		anim_sprite.play("hurt")
	else:
		anim_sprite.play("death")
	set_process(true)
	var t = create_tween().set_parallel()
	t.tween_property(anim_sprite.get_material(), "shader_param/hit_strength",
			0.0, 0.5).from(1.0)
	t.tween_property(health_bar, "value", percent, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	yield(t, "finished")
	if percent > 0:
		anim_sprite.play("normal")
	set_process(false)
	health_bar.rect_position = Vector2()

extends Area2D

var dir := Vector2.RIGHT
var speed := 160


func _physics_process(delta: float) -> void:
	position += dir * speed * delta


func _on_Fireball_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.hit(sign(dir.x))
	$CollisionShape2D.call_deferred("set_disabled", true)
	$ImpactSFX.play()


func _on_FreeTimer_timeout() -> void:
	queue_free()


func _on_ImpactSFX_finished() -> void:
	queue_free()

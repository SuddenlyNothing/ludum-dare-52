extends Node2D

const Bone := preload("res://characters/Bone.tscn")

export(NodePath) var player_path
export(NodePath) var dragon_path

var titles := [
	"Baby Dragon",
	"Teen Dragon",
]
var dragons := [
	preload("res://characters/DragonBaby.tscn"),
	preload("res://characters/DragonTeen.tscn"),
]
var bone_offset := Vector2(0, -10)
var t: SceneTreeTween
var downed := false
var dragon_ind := 1

onready var dragon := get_node(dragon_path)
onready var player := get_node(player_path)

onready var health_bar := $CanvasLayer/Control/M/V/HealthBar
onready var title := $CanvasLayer/Control/M/V/Title
onready var hint := $CanvasLayer/Control/M/V/Hint
onready var death_delay_timer := $DeathDelayTimer
onready var down_timer := $DownTimer


func _ready() -> void:
	connect_dragon()
	set_process(false)
	player.connect("threw", self, "_on_player_threw")


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("feed"):
		set_process(false)
		player.throw(sign(dragon.position.x - player.position.x))


func connect_dragon() -> void:
	dragon.connect("died", self, "_on_dragon_died")
	dragon.connect("downed", self, "_on_dragon_downed")
	dragon.connect("hit", self, "_on_dragon_hit")


func _on_dragon_died(angered: bool) -> void:
	if angered:
		dragon.queue_free()
	else:
		death_delay_timer.start()


func _on_dragon_hit(percent: float) -> void:
	if t:
		t.kill()
	t = create_tween()
	t.tween_property(health_bar, "value", percent, 0.3)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if downed:
		downed = false
		set_process(false)
		hint.hide()
		dragon.wake()


func _on_dragon_downed() -> void:
	set_process(true)
	down_timer.start()
	hint.show()
	downed = true


func _on_dragon_fed() -> void:
	dragon.feed()


func _on_dragon_downed_rejected() -> void:
	hint.hide()
	set_process(false)


func _on_player_threw() -> void:
	downed = false
	set_process(false)
	hint.hide()
	var b := Bone.instance()
	b.position = player.position + bone_offset
	b.end_pos = dragon.mouth_pos.global_position
	get_parent().add_child(b)
	b.connect("arrived", self, "_on_dragon_fed")


func _on_DeathDelayTimer_timeout() -> void:
	var prev_pos: Vector2 = dragon.position
	dragon.queue_free()
	if dragon_ind >= dragons.size():
		return
	dragon = dragons[dragon_ind].instance()
	dragon.position = prev_pos
	get_parent().add_child(dragon)
	connect_dragon()
	health_bar.value = 1
	dragon_ind += 1


func _on_DownTimer_timeout() -> void:
	if downed:
		hint.hide()
		set_process(false)
		downed = false
		dragon.wake()

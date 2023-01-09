extends StateMachine


func _ready() -> void:
	add_state("evolve")
	add_state("idle")
	add_state("swipe")
	add_state("fireball")
	add_state("down")
	add_state("death")
	call_deferred("set_state", "evolve")


# Contains state logic.
func _state_logic(delta: float) -> void:
	match state:
		states.idle:
			parent.move_idle(delta)
		states.swipe:
			parent.move_swipe(delta)
		states.fireball:
			pass
		states.down:
			parent.move_down(delta)
		states.death:
			parent.move_death(delta)


# Return value will be used to change state.
func _get_transition(delta: float):
	match state:
		states.idle:
			if parent.idle_wait_timer.is_stopped():
				return states.fireball
		states.swipe:
			pass
		states.fireball:
			pass
		states.down:
			pass
		states.death:
			pass
	return null


# Called on entering state.
# new_state is the state being entered.
# old_state is the state being exited.
func _enter_state(new_state: String, old_state) -> void:
	match new_state:
		states.evolve:
			parent.play_anim("evolve")
			parent.idle_wait_timer.start()
			parent.idle_velocity = Vector2()
		states.idle:
			parent.play_anim("idle")
		states.swipe:
			parent.play_anim("idle")
			parent.in_range = false
		states.fireball:
			parent.play_anim("fireball")
			parent.fireball_count = parent.fireballs
		states.down:
			parent.play_anim("falling")
			parent.landed = false
			parent.fall_velocity = Vector2(0, -500)
			parent.set_collision_bit(true)
		states.death:
			parent.landed = false
			parent.fall_velocity = Vector2(0, -500)
			parent.set_collision_bit(true)
			parent.play_anim("falling")


# Called on exiting state.
# old_state is the state being exited.
# new_state is the state being entered.
func _exit_state(old_state, new_state: String) -> void:
	match old_state:
		states.idle:
			pass
		states.swipe:
			pass
		states.fireball:
			pass
		states.down:
			parent.set_collision_bit(false)
		states.death:
			pass

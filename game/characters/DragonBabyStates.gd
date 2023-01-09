extends StateMachine

func _ready() -> void:
	add_state("idle")
	add_state("charge")
	add_state("down")
	add_state("death")
	call_deferred("set_state", "idle")


# Contains state logic.
func _state_logic(delta: float) -> void:
	match state:
		states.idle:
			pass
		states.charge:
			parent.move_charge(delta)
		states.down:
			pass
		states.death:
			pass


# Return value will be used to change state.
func _get_transition(delta: float):
	match state:
		states.idle:
			if parent.charge_wait_timer.is_stopped():
				return states.charge
		states.charge:
			if parent.velocity.x == 0:
				return states.idle
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
		states.idle:
			parent.play_anim("idle")
			parent.charge_wait_timer.start()
		states.charge:
			parent.play_anim("charge_prep")
			parent.charging = false
			parent.set_charge_velocity()
		states.down:
			parent.play_anim("down")
			parent.down_sfx.play()
			parent.emit_signal("downed")
		states.death:
			parent.play_anim("death")
			parent.death_sfx.play()
			parent.set_body_collision_disabled(true)


# Called on exiting state.
# old_state is the state being exited.
# new_state is the state being entered.
func _exit_state(old_state, new_state: String) -> void:
	match old_state:
		states.idle:
			parent.charge_wait_timer.stop()
		states.charge:
			parent.flip()
			parent.set_hitbox_disabled(true)
		states.down:
			pass
		states.death:
			pass

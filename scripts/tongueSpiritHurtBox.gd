extends Area2D

func take_spear_damage(globalPosPlayer):
	get_parent().take_spear_damage(globalPosPlayer)
	
func take_punch_damage(globalPosPlayer):
	get_parent().take_punch_damage(globalPosPlayer)
	
func take_dismantle_damage():
	get_parent().take_dismantle_damage()

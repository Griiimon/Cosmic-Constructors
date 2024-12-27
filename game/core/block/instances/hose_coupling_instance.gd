class_name HoseCouplingInstance
extends TubeGroupMemberInstance

var hose: Rope



func interact(grid: BlockGrid, grid_block: GridBlock, player: Player):
	if not hose:
		if player.action_state_machine.attach_rope_state.is_current_state():
			hose= player.action_state_machine.attach_rope_state.rope
			player.attach_rope(self)
			linked_system.merge((hose.start as HoseCouplingInstance).linked_system)
		else:
			hose= player.attach_rope(self)
	

func can_interact(grid: BlockGrid, grid_block: GridBlock, player: Player)-> bool:
	return not hose or player.action_state_machine.attach_rope_state.is_current_state() 

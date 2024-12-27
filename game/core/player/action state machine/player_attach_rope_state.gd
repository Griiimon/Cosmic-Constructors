class_name PlayerAttachRopeState
extends PlayerActionStateMachineState

var rope: Rope



func on_physics_process(_delta: float):
	interaction_logic()

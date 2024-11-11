extends HandObject

var drill_interval: Timer
var player: Player


func _ready():
	super()
	
	drill_interval= Timer.new()
	drill_interval.autostart= false
	drill_interval.timeout.connect(do_drill)
	add_child(drill_interval)


func start_using():
	if animation_player:
		animation_player.play("use")
	drill_interval.start()


func stop_using():
	if animation_player:
		animation_player.play("RESET")
	drill_interval.stop()


func do_drill():
	player.drill()

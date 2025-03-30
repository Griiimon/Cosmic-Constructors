extends HandObject

var drill_cooldown: Timer


func _ready():
	super()
	
	drill_cooldown= Timer.new()
	drill_cooldown.autostart= false
	drill_cooldown.timeout.connect(do_drill)
	add_child(drill_cooldown)


func start_using():
	super()
	player.drill_shapecast.enabled= true
	drill_cooldown.start()



func stop_using():
	super()
	player.drill_shapecast.enabled= false
	drill_cooldown.stop()


func do_drill():
	player.drill()

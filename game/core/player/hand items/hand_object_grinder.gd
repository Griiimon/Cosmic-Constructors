extends HandObject

var grind_cooldown: Timer


func _ready():
	super()
	
	grind_cooldown= Timer.new()
	grind_cooldown.autostart= false
	grind_cooldown.timeout.connect(do_grind)
	add_child(grind_cooldown)


func start_using():
	super()
	player.grind_shapecast.enabled= true
	grind_cooldown.start()


func stop_using():
	super()
	player.grind_shapecast.enabled= false
	grind_cooldown.stop()


func do_grind():
	player.grind()

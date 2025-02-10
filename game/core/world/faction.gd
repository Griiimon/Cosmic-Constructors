class_name Faction

var id: int
var name: String
var members: Array[String]
var is_default:= false

var active_members: Array[BasePlayer]

var extra_data: Dictionary



func _init(_name: String, _is_default: bool= false):
	name= _name
	is_default= _is_default
	
	
func add(player: BasePlayer):
	assert(not NetworkManager.is_client)
	assert(not player in active_members)
	active_members.append(player)
	if not player.player_name in members:
		members.append(player.player_name)
	player.faction= self


func serialize()-> Dictionary:
	return { "name": name, "members": members, "default": is_default, "extra_data": extra_data }


static func deserialize(data: Dictionary)-> Faction:
	var faction:= Faction.new(data["name"], data["default"])
	faction.members.assign(data["members"])
	faction.extra_data= data["extra_data"]
	return faction

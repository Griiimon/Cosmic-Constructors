class_name Faction

var name: String
var members: Array[String]
var is_default:= false

var active_members: Array[BasePlayer]



func _init(_name: String, _is_default: bool= false):
	name= _name
	is_default= _is_default
	
	
func add(player: BasePlayer):
	assert(not NetworkManager.is_client)
	assert(not player in active_members)
	active_members.append(player)
	if not player.player_name in members:
		members.append(player.player_name)


func serialize()-> Dictionary:
	return { "name": name, "members": members, "default": is_default }


static func deserialize(data: Dictionary)-> Faction:
	var faction:= Faction.new(data["name"], data["default"])
	faction.members= data["members"]
	return faction

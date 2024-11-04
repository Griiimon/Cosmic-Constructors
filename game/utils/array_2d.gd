class_name Array2D


var width
var height
var arr= []
var default_value



func clone()-> Array2D:
	var result:= Array2D.new(width, height, default_value)
	result.arr= arr.duplicate()
	return result


func serialize(callable= null)-> Dictionary:
	var tmp_arr= arr
	if callable:
		tmp_arr= []
		for item in arr:
			var val= null
			if item != null:
				val= callable.call(item)
			tmp_arr.append(val)

	return {"width": width, "height": height, "default_value": default_value, "arr": tmp_arr}


static func deserialize(dict: Dictionary):
	var ret= Array2D.new(dict.width, dict.height, dict.default_value)
	ret.arr= dict.arr
	return ret


# init with width, height and default value
func _init(w: int, h: int, val= null):
	width= w
	height= h
	default_value= val
	for i in (width * height):
		arr.append(val)


# set value for position x,y. If overwrite is
# false won't overwrite any value other than the default value
func put(x: int, y: int, val, overwrite= true):
	if not overwrite:
		if arr[x + y * width] != default_value:
			return
	arr[x + y * width]= val


# set value via index
func put_index(i: int, val):
	arr[i]= val


# read value via index
func read_index(i: int):
	return arr[i]


# get value at position x, y 
func read(x: int, y: int):
	assert(x >= 0 and x < width and y >= 0 and y < height, str(x, ",", y))
	return arr[x + y * width]


# read value at position given by vector
func readv(vec: Vector2i):
	return read(vec.x, vec.y)


# set value at position given by vector
func putv(vec: Vector2i, val, overwrite= true):
	put(vec.x, vec.y, val, overwrite)


# clear/fill whole array with value
func clear(value):
	for i in width * height:
		arr[i]= value


# checks if x, y is inside arrays dimensions
func is_in_bounds(x: int, y: int)-> bool:
	return x >= 0 and y >= 0 and x < width and y < height


# checks if vector is inside arrays dimensions
func is_in_boundsv(vec: Vector2)-> bool:
	return is_in_bounds(int(vec.x), int(vec.y))


# returns smallest value in the array. Only works 
# with number values and possibly strings
func get_min_value():
	var res= null
	for i in width * height:
		if res == null or arr[i] < res:
			res= arr[i]
	return res


func get_ratio()-> float:
	var ctr:= 0
	for i in arr.size():
		if arr[i] != default_value:
			ctr+= 1
	
	return float(ctr) / arr.size()


#func save_to_file(file_name):
#	var file: File = File.new()
#	if file.open(file_name, File.WRITE) != OK:
#		printerr("Couldnt open file ", file_name)
#	file.store_var(arr)
#	file.close()
#
#
#func load_from_file(file_name):
#	var file: File = File.new()
#	if file.open(file_name, File.READ) != OK:
#		printerr("Couldnt open file ", file_name)
#	arr= file.get_var()
#	file.close()


# outputs the array contents to console. Has default output delay
# per line as to not overflow the output console. Will need a
# reference to any node withing the scene tree. If omitted all
# output is instant
func console_dump(separator= "", node= null, initial_delay= 0.5):
	if node:
		await node.get_tree().create_timer(initial_delay).timeout
	print("Dumping array ", width, "x", height)
	for y in height:
		var s= ""
		for x in width:
			var val= read(x, y)
			if val is bool:
				val= 1 if val else 0
			s+= str(val) + separator
		print(s)
		if node:
			await node.get_tree().create_timer(0.05).timeout


static func bool_from_string(s: String)-> Array2D:
	var str_arr
	if s.contains("|"):
		str_arr= s.split("|")
	else:
		str_arr= s.split("\n")
		
	var new_width= 0
	var new_height= str_arr.size()
	for line in str_arr:
		new_width= max(new_width, line.length())
	
	var result= Array2D.new(new_width, new_height, false)

	for y in new_height:
		var line= str_arr[y]
		for x in new_width:
			var c= line[x]
			result.put(x, y, true if (c == "1" or c.to_upper() == "X") else false)

	return result 

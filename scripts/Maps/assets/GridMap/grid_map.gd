@tool
extends Node

@export var map_size = Vector3(10, 10, 10)
@export var room_size = Vector3(4, 4, 4)
@export_range(1, 100) var max_rooms: int = 20

@export var room_scenes: Array[PackedScene] = []:
	set(v):
		for scene in v:
			if scene != null:
				if scene.instantiate() is not GridRoom:
					push_error("PackedScene is not of type GridRoom")
					return
		room_scenes = v

var rooms: Array[GridRoom]

func generate():
	rooms.append(room_scenes[0].instantiate())
	recursive_room_creation(rooms[0])
	
	for room in rooms:
		add_child(room)

func recursive_room_creation(current_room: GridRoom):
	if rooms.size() >= max_rooms:
		return
	
	var connection = get_rand_valid_connection(current_room.connections)
	var new_pos = update_pos(current_room.get_position(), connection)
	
	# check if room exists at position. 
	# if so add a connection to that room otherwise add a new room
	var room_index = get_room_index_at(new_pos)
	if room_index > -1:
		# connect to room
		current_room.CreateConnection(connection)
		rooms[room_index].CreateConnection(get_opposite_connection(connection))
		recursive_room_creation(rooms[get_rand_valid_room_index()])
	else:
		# if new position is not in bounds set connection to true so it will 
		# not register as a valid connection. Otherwise create new room
		if !in_map_bounds(new_pos):
			current_room.connections[connection] = true
			recursive_room_creation(rooms[get_rand_valid_room_index()])
		else:
			# create new room
			var new_room = create_new_room_at(new_pos)
			current_room.CreateConnection(connection)
			new_room.CreateConnection(get_opposite_connection(connection))
			rooms.append(new_room)
			recursive_room_creation(new_room)

func has_open_connections(connections: Dictionary):
	for connection in connections:
		if !connections[connection]:
			return true

func get_rand_valid_connection(connections: Dictionary):
	var valid_connections: Array[GridRoom.ConnectionType]
	for connection in connections:
		if !connections[connection]:
			valid_connections.append(connection)
	var valid_count = valid_connections.size()
	if valid_count > 0:
		return valid_connections[randi() % valid_count]

func get_rand_valid_room_index():
	var valid_room_indices: Array[int]
	var index = 0
	for room in rooms:
		if has_open_connections(room.connections):
			valid_room_indices.append(index)
		index += 1
	
	var valid_count = valid_room_indices.size()
	if valid_count:
		return valid_room_indices[randi() % valid_count]

func update_pos(pos: Vector3, connection_type: GridRoom.ConnectionType):
	match connection_type:
		GridRoom.ConnectionType.NORTH_WALL:
			pos.z -= room_size.z
		GridRoom.ConnectionType.SOUTH_WALL:
			pos.z += room_size.z
		GridRoom.ConnectionType.EAST_WALL:
			pos.x += room_size.x
		GridRoom.ConnectionType.WEST_WALL:
			pos.x -= room_size.x
		GridRoom.ConnectionType.CEILING:
			pos.y += room_size.y
		GridRoom.ConnectionType.FLOOR:
			pos.y -= room_size.y
	return pos

func get_room_index_at(pos: Vector3):
	var index = 0
	for room in rooms:
		if room.get_position() == pos:
			return index
		index += 1
	return -1

func create_new_room_at(pos: Vector3):
	var new_room = room_scenes[0].instantiate()
	new_room.set_position(pos)
	return new_room

func get_opposite_connection(connection_type: GridRoom.ConnectionType):
	match connection_type:
		GridRoom.ConnectionType.NORTH_WALL:
			return GridRoom.ConnectionType.SOUTH_WALL
		GridRoom.ConnectionType.SOUTH_WALL:
			return GridRoom.ConnectionType.NORTH_WALL
		GridRoom.ConnectionType.EAST_WALL:
			return GridRoom.ConnectionType.WEST_WALL
		GridRoom.ConnectionType.WEST_WALL:
			return GridRoom.ConnectionType.EAST_WALL
		GridRoom.ConnectionType.FLOOR:
			return GridRoom.ConnectionType.CEILING
		GridRoom.ConnectionType.CEILING:
			return GridRoom.ConnectionType.FLOOR

func in_map_bounds(pos: Vector3):
	var lower_bounds = -1.0 * (map_size/2.0) * room_size
	var upper_bounds = map_size/2.0 * room_size
	if pos.x < lower_bounds.x || pos.x > upper_bounds.x:
		return false
	elif pos.y < lower_bounds.y || pos.y > upper_bounds.y:
		return false
	elif pos.z < lower_bounds.z || pos.z > upper_bounds.z:
		return false
	else:
		return true
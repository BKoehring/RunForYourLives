extends CharacterBody3D

class_name Entity

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	
	for child in get_parent().get_children():
		if child is Level:
			child.register_player(self)

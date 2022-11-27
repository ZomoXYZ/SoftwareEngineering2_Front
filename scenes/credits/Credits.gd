extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var current = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	var pos = Vector2(0,251)
	var siz = Vector2(480,476)
	$Background/MiddleCover.set_position(pos)
	$Background/MiddleCover.set_size(siz)
	$Background/MiddleCover.get_child(current).show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass




func _on_ToMainMenu_pressed():
	$Background/MiddleCover.get_child(current).hide()
	$AnimationPlayer.play("Leave_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/main_menu/Main_Menu.tscn")


func _on_Next_pressed():
	$Background/MiddleCover.get_child(current).hide()
	current += 1
	if current == $Background/MiddleCover.get_children().size():
		current = 0
	$Background/MiddleCover.get_child(current).show()

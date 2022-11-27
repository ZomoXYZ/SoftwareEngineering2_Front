extends Control


# Declare member variables here. Examples:
var current = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	var pos = Vector2(0,251)
	var siz = Vector2(480,476)
	$Background/MiddleCover.set_position(pos)
	$Background/MiddleCover.set_size(siz)
	$Background/MiddleCover/Part1.show()


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


func _on_Back_pressed():
	$Background/MiddleCover.get_child(current).hide()
	current -= 1
	if current == -1:
		current = 11
	$Background/MiddleCover.get_child(current).show()

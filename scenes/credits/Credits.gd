extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var current = 0
var clickable = false
var play = load("res://WanAndOnlyPlay.png")
var stand = load("res://WanAndOnlyStand.png")

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
	print(current)
	$Background/MiddleCover.get_child(current).hide()
	current += 1
	if current == 2:
		clickable = true
	else:
		clickable = false
		
	if current == $Background/MiddleCover.get_children().size():
		current = 0
	$Background/MiddleCover.get_child(current).show()


func _on_Button_button_down():
	if clickable:
		$Background/MiddleCover/Part3/WanAndOnlyStand.texture = play
		clickable = false
		yield(get_tree().create_timer(2),"timeout")
		$Background/MiddleCover/Part3/WanAndOnlyStand.texture = stand
		clickable = true

extends Node

export(PackedScene) var cardScene


# Called when the node enters the scene tree for the first time.
func _ready():
	if StartVars.singlePlayer:
		$Pause/Panel/LobbyID.text = "Offline"
	else:
		$Pause/Panel/obbyID.text = "ID: 123456"
	var cardInstance
	$Pause.hide()
	for i in 5:
		cardInstance = cardScene.instance()
		cardInstance.set_rotation(PI / 2)
		$Background/HandBox.add_child(cardInstance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#Pause shows pause overlay
func _on_PauseButton_pressed():
	$Pause.show()
	$AnimationPlayer.play("Pause_Transition")
	yield($AnimationPlayer, "animation_finished")

#Resume hides the pause again
func _on_Resume_pressed():
	$AnimationPlayer.play_backwards("Pause_Transition")
	yield($AnimationPlayer, "animation_finished")
	$Pause.hide()

#Returns to the lobby list or main menu if this is a multi or single player game
func _on_Leave_pressed():
	if StartVars.singlePlayer:
		StartVars.singlePlayer = false
		get_tree().change_scene("res://scenes/main_menu/Main_Menu.tscn")
	else:
		get_tree().change_scene("res://scenes/lobby_list/Lobby_List.tscn")

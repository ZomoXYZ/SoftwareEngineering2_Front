extends Node

export(PackedScene) var cardScene


# Called when the node enters the scene tree for the first time.
func _ready():
	#First I check if this is a single player game or not, if so then I remove lobby ID and replace it with offline
	if StartVars.singlePlayer:
		$Pause/Panel/LobbyID.text = "Offline"
		$Pause/PlayerList/KickPlayer.hide()
	else:
		$Pause/Panel/LobbyID.text = "ID: 123456"
	
	#Also hide Pause menu. This is important because the pause menu is an overlay
	$Pause.hide()
	#Spawning in cards
	var cardInstance
	for i in 5:
		randomize()
		var rand = randi() % 15

		cardInstance = cardScene.instance()
		cardInstance.set_rotation(PI / 2)
		cardInstance.selfValue = rand
		$Background/HandBox.add_child(cardInstance)
	
	#Connects the card buttons
	var currentCard
	for cardWrapper in $Background/HandBox.get_children():
		cardWrapper.connect("pressed_with_val", self, "_on_Card_pressed")
		

func _on_Card_pressed(card):
	var playsWith = StartVars.validHands[card.selfName()]
	
	for cardObj in $Background/HandBox.get_children():
		if cardObj.selfName() in playsWith:
			print(cardObj.selfName())

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#Pause shows pause overlay
func _on_PauseButton_pressed():
	#The pause animation changes the opacity of the pause menu, but having no opacity is not the same as hiding because it would still be tangible
	#So we have to show() first then play the animation
	$Pause.show()
	$AnimationPlayer.play("Pause_Transition")
	yield($AnimationPlayer, "animation_finished")

#Resume hides the pause again
func _on_Resume_pressed():
	#Same as above but in reverse order, play the opacity change, then hide it so that buttons on main can be clicked
	$AnimationPlayer.play_backwards("Pause_Transition")
	yield($AnimationPlayer, "animation_finished")
	$Pause.hide()

#Returns to the lobby list or main menu if this is a multi or single player game
func _on_Leave_pressed():
	LobbyConn.leave()
	if StartVars.singlePlayer:
		StartVars.singlePlayer = false
		get_tree().change_scene("res://scenes/main_menu/Main_Menu.tscn")
	else:
		get_tree().change_scene("res://scenes/lobby_list/Lobby_List.tscn")

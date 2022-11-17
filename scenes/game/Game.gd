extends Node

export(PackedScene) var cardScene

#We preload the image from files so we can use this variable is needeth beedeth
var button_empty = preload("res://assets/styles/button_empty.tres")
var button_green = preload("res://assets/styles/button_green.tres")
var button_red = preload("res://assets/styles/button_red.tres")


# Called when the node enters the scene tree for the first time.
func _ready():
	#First I check if this is a single player game or not, if so then I remove lobby ID and replace it with offline
	var cardInstance
	randomize()
	#spawning cards
	if StartVars.singlePlayer:
		$Pause/Panel/LobbyID.text = "Offline"
		$Pause/PlayerList/KickPlayer.hide()
		for i in 5:
			var rand = randi() % 15
			cardInstance = cardScene.instance()
			cardInstance.set_rotation(PI / 2)
			cardInstance.selfValue = rand
			$Background/HandBox.add_child(cardInstance)
	else:
		$Pause/Panel/LobbyID.text = "ID: 123456"
		for i in len(LobbyConn.Cards):
			cardInstance = cardScene.instance()
			cardInstance.set_rotation(PI / 2)
			cardInstance.selfValue = LobbyConn.Cards[i]
			$Background/HandBox.add_child(cardInstance)
	
	#Also hide Pause menu. This is important because the pause menu is an overlay
	$Pause.hide()


	
	#Connects the card buttons
	var currentCard
	for cardWrapper in $Background/HandBox.get_children():
		cardWrapper.connect("pressed_with_val", self, "_on_Card_pressed")
		

func _on_Card_pressed(card):
	#card.selected = true
	var playsWith = StartVars.validHands[card.selfName()]
	var position = card.get_child(0).get_position()
	if !card.get_child(0).get_child(0).is_visible():
		card.get_child(0).set_position(Vector2(position.x, position.y-30))
		for cardObj in $Background/HandBox.get_children():
			cardObj.get_child(0).get_child(0).show()
			if cardObj.selfName() in playsWith:
				cardObj.get_child(0).get_child(0).hide()

			#TODO: FIX THIS
			if card == cardObj:
				if cardObj.selected:
					var tempPos = cardObj.get_child(0).get_position()
					cardObj.get_child(0).set_position(Vector2(tempPos.x, position.y+30))
					cardObj.selected = false
					for cardObj2 in $Background/HandBox.get_children():
						cardObj2.get_child(0).get_child(0).hide()
					break
				else:
					cardObj.selected = true
				

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#Pause shows pause overlay
func _on_PauseButton_pressed():
	#The pause animation changes the opacity of the pause menu, but having no opacity is not the same as hiding because it would still be tangible
	#So we have to show() first then play the animation
	$Pause.show()
	if StartVars.singlePlayer:
		#If single player I went ahead and set bots and changed the lobby ID to offline
		$Pause/Panel/LobbyID.text = "Offline"
		$Pause/PlayerList/Player2.text = "Easy \nBot "
		$Pause/PlayerList/Player3.text = "Medium \nBot "
		$Pause/PlayerList/Player4.text = "Hard \nBot "
	else:
		var players = LobbyConn.Players
		var host = LobbyConn.Host
		var ID = LobbyConn.Code
		var current
		$Pause/PlayerList/Player1.text = "%s %s" % [host.name['adjective'], host.name['noun']]
		$Pause/PlayerList/Player1.add_stylebox_override("normal", button_red)
		#If online, then I set all the other players slots to empty and hid their playerIcons
		$Pause/Panel/LobbyID.text = "ID: %s" %ID
		$Pause/PlayerList/Player2.add_stylebox_override("normal", button_empty)
		$Pause/PlayerList/Player2.text = ""
		$Pause/PlayerList/Player2/PlayerIcon.hide()
		$Pause/PlayerList/Player3.add_stylebox_override("normal", button_empty)
		$Pause/PlayerList/Player3.text = ""
		$Pause/PlayerList/Player3/PlayerIcon.hide()
		$Pause/PlayerList/Player4.add_stylebox_override("normal", button_empty)
		$Pause/PlayerList/Player4.text = ""
		$Pause/PlayerList/Player4/PlayerIcon.hide()
		for i in range(len(players)):
			current = $Background/PlayerList.get_child(i + 1)
			current.text = "%s %s" % [players[i]['name']['adjective'], players[i]['name']['noun']]
			current.add_stylebox_override("normal", button_green)
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

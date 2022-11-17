extends Node

#There might be a better way to do this but this is the only thing I found thro google
#We preload the image from files so we can use this variable is needeth beedeth
var button_empty = preload("res://assets/styles/button_empty.tres")
var button_green = preload("res://assets/styles/button_green.tres")
var button_red = preload("res://assets/styles/button_red.tres")

export(PackedScene) var cardScene

func connect_signals():
	if StartVars.singlePlayer:
		LobbySP.connect("disconnected", self, "_on_disconnected")
	else:
		LobbyConn.connect("disconnected", self, "_on_disconnected")

func fill_cards():
	var cards
	if StartVars.singlePlayer:
		cards = LobbySP.Cards
	else:
		cards = LobbyConn.Cards

	# display at most 5 cards
	var count = clamp(len(cards), 0, 5)
	for i in count:
		var cardInstance = cardScene.instance()
		cardInstance.connect("pressed_with_val", self, "_on_Card_pressed")
		cardInstance.set_rotation(PI / 2)
		cardInstance.selfValue = cards[i]
		$Background/HandBox.add_child(cardInstance)

# Called when the node enters the scene tree for the first time.
func _ready():
	connect_signals()

	# update UI
	$Pause.hide()
	if StartVars.singlePlayer:
		$Pause/Panel/LobbyID.text = "Offline"
		$Pause/PlayerList/KickPlayer.hide()
	else:
		$Pause/Panel/LobbyID.text = "ID: %s" % LobbyConn.Code

	fill_cards()
		

func _on_Card_pressed(card):

	# if it's selected, the user can deselect
	# if it's not selected, make sure it can be played first
	if card.selected:
		card.deselect()
	elif card.canSelect:
		card.select()

	# get list of selected cards
	var selectedCards = []
	for child in $Background/HandBox.get_children():
		if child.selected:
			selectedCards.append(child.selfValue)

	# figure out which cards can be selected, returns null if no cards are selected
	var selectableCards = StartVars.getValidCards(selectedCards)

	# loop through cards, if any do not exist within selectableCards, grey them out
	for child in $Background/HandBox.get_children():

		if selectableCards == null or child.selfValue in selectableCards or child.selected:
			child.setCanSelect(true)
		else:
			child.setCanSelect(false)
				
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
	if StartVars.singlePlayer:
		StartVars.singlePlayer = false
		get_tree().change_scene("res://scenes/main_menu/Main_Menu.tscn")
	else:
		LobbyConn.leave()

func _on_disconnected():
	get_tree().change_scene("res://scenes/lobby_list/Lobby_List.tscn")

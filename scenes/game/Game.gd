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
		LobbyConn.connect("player_turn", self, "_on_playerturn")
		LobbyConn.connect("card_drew", self, "_on_carddrew")
		LobbyConn.connect("card_discarded", self, "_on_carddiscarded")
		LobbyConn.connect("cards_played", self, "_on_cardsplayed")
		LobbyConn.connect("turn_ended", self, "_on_turnended")
		LobbyConn.connect("game_over", self, "_on_gameover")
		LobbyConn.join_game()

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

func fill_players_pausebutton():
	# variables
	var players = []
	var codeText = ""

	# fill variables
	if StartVars.singlePlayer:
		players = LobbySP.getAllPlayers()
		codeText = "OFFLINE"
	else:
		players = LobbyConn.getAllPlayers()
		codeText = "ID: %s" % LobbyConn.Code
		
	# show lobby code
	$Pause/Panel/LobbyID.text = codeText

	# fill player list
	for i in 4:
		var current = $Pause/PlayerList.get_child(i)
		if i < len(players):
			current.text = "%s %s" % [players[i]['name']['adjective'], players[i]['name']['noun']]
			current.get_node("PlayerIcon").show()
			if i == 0:
				current.add_stylebox_override("normal", button_red)
			else:
				current.add_stylebox_override("normal", button_green)
		else:
			current.text = ""
			current.get_node("PlayerIcon").hide()
			current.add_stylebox_override("normal", button_empty)
				
#Pause shows pause overlay
func _on_PauseButton_pressed():
	#The pause animation changes the opacity of the pause menu, but having no opacity is not the same as hiding because it would still be tangible
	#So we have to show() first then play the animation
	$Pause.show()
	fill_players_pausebutton()
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

func _on_playerturn(player):
	if LobbyConn.isMyTurn():
		print("My turn")
	else:
		print("Player %s's turn" % player)

func _on_carddrew(from, card): # from: DrawFrom.DRAW_FROM_DECK or DrawFrom.DRAW_FROM_DISCARD
	print("I drew %s from %s" % [StartVars.CardName(card), LobbyConn.DrawFrom.keys()[from]])

func _on_carddiscarded(card):
	print("I discarded %s" % StartVars.CardName(card))

func _on_cardsplayed(cards): # cards will be null if passed
	var cardStr = []
	for card in cards:
		cardStr.append(StartVars.CardName(card))
	print("I played %s" % cardStr)

func _on_turnended(cards): # cards automatically drawn
	var cardStr = []
	for card in cards:
		cardStr.append(StartVars.CardName(card))
	print("I finished my card by drawing %s" % cardStr)

func _on_gameover(player): # playerID winner
	print("Player %s won" % player)

extends Node

#There might be a better way to do this but this is the only thing I found thro google
#We preload the image from files so we can use this variable is needeth beedeth
var button_empty = preload("res://assets/styles/button_empty.tres")
var button_empty2 = preload("res://assets/styles/button_empty2.tres")
var button_green = preload("res://assets/styles/button_green.tres")
var button_red = preload("res://assets/styles/button_red.tres")

export(PackedScene) var cardScene

func playerIndexToNode(playerIndex):
	var myIndex
	if !StartVars.singlePlayer:
		for i in range(LobbyConn.Players.size()):
			if LobbyConn.Players[i].id == UserData.ID:
				myIndex = i
				break
	else:
		myIndex = 0
		playerIndex = 0
	
	if playerIndex == myIndex:
		return $Background/Players.get_node("Player1")
	elif playerIndex < myIndex:
		return $Background/Players.get_node("Player%s" % (playerIndex + 2))
	else:
		return $Background/Players.get_node("Player%s" % (playerIndex + 1))

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
		LobbyConn.connect("players_updated", self, "_on_playersupdated")
		LobbyConn.join_game()

func fill_cards(enabled):
	var cards
	if StartVars.singlePlayer:
		cards = LobbySP.Cards
	else:
		cards = LobbyConn.Cards

	for child in $Background/HandBox.get_children():
		child.queue_free()

	# display at most 5 cards
	var count = clamp(len(cards), 0, 5)
	for i in count:
		var cardInstance = cardScene.instance()
		cardInstance.connect("pressed_with_val", self, "_on_Card_pressed")
		cardInstance.set_rotation(PI / 2)
		cardInstance.selfValue = cards[i]
		$Background/HandBox.add_child(cardInstance)
		cardInstance.setCanSelect(enabled)

# Called when the node enters the scene tree for the first time.
func _ready():
	connect_signals()
	var fix = Vector2(176,100)
	$Background/DrawPileBox/CardRotate/Card.set_rotation(-PI)
	$Background/DrawPileBox/CardRotate/Card.set_position(fix)
	# update UI
	$Pause.hide()
	if StartVars.singlePlayer:
		$Pause/Panel/LobbyID.text = "Offline"
		$Pause/PlayerList/KickPlayer.hide()
	else:
		$Pause/Panel/LobbyID.text = "ID: %s" % LobbyConn.Code
	
	if !LobbyConn.isHost():
		$Pause/PlayerList/KickPlayer.hide()
	fill_players_gameturn(true)
		
func get_selected_cards():
	var selectedCards = []
	for child in $Background/HandBox.get_children():
		if child.selected:
			selectedCards.append(child.selfValue)
	return selectedCards

func _on_Card_pressed(card):

	# if it's selected, the user can deselect
	# if it's not selected, make sure it can be played first
	if card.selected:
		card.deselect()
	elif card.canSelect:
		card.select()

	# get list of selected cards
	var selectedCards = get_selected_cards()

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
		players = LobbySP.Players
		codeText = "OFFLINE"
	else:
		players = LobbyConn.Players
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
			
func fill_players_gameturn(beforeTurns=false):
	# variables
	var players = []

	# fill variables
	if StartVars.singlePlayer:
		players = LobbySP.Players
	else:
		players = LobbyConn.Players
	
	# reset player states
	for i in 4:
		var current = playerIndexToNode(i)
		$Pause.hide()
		if i < len(players):
			current.get_node("Name").text = "%s %s" % [players[i]['name']['adjective'], players[i]['name']['noun']]
			if beforeTurns:
				current.get_node("Score").text = "%s" %00
			else:
				current.get_node("Score").text = "%s" %LobbyConn.Points[i]
			current.get_node("PlayerIcon").show()
			current.add_stylebox_override("panel", button_empty)
			current.get_node("Highlight").add_stylebox_override("panel", button_green)
		else:
			current.get_node("PlayerIcon").hide()
			current.add_stylebox_override("panel", button_empty2)
			for x in current.get_children():
				x.hide()
	
	if !beforeTurns:
		# set current turn visually
		var current
		if StartVars.singlePlayer:
			print("current turn, singleplayer, this will error because `current` is not defined")
		else:
			current = playerIndexToNode(LobbyConn.getTurnIndex())
		
		current.get_node("Highlight").add_stylebox_override("panel", button_red)
		current.add_stylebox_override("panel", button_green)
	
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

func _on_Submit_pressed():
	var selectedCards = get_selected_cards()
	LobbyConn.play(selectedCards)

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
	fill_players_gameturn()
	fill_cards(false)

	if LobbyConn.isMyTurn():
		print("My turn")
		LobbyConn.draw(LobbyConn.DrawFrom.DECK)
	else:
		print("Player %s's turn" % player)

# from: DrawFrom.DRAW_FROM_DECK or DrawFrom.DRAW_FROM_DISCARD
# card will be null if it isnt your turn
func _on_carddrew(from, card):
	if LobbyConn.isMyTurn():
		print("I drew %s from %s" % [StartVars.CardName(card), LobbyConn.DrawFrom.keys()[from]])
		LobbyConn.discard(card)
	else:
		print("Player %s drew from %s" % [LobbyConn.Turn, LobbyConn.DrawFrom.keys()[from]])

func _on_carddiscarded(card):
	if LobbyConn.isMyTurn():
		fill_cards(true)
		# temp print
		print("I discarded %s" % StartVars.CardName(card))
	else:
		fill_cards(false)
		print("Player %s discarded %s" % [LobbyConn.Turn, StartVars.CardName(card)])

func _on_cardsplayed(cards): # cards will be null if passed
	fill_cards(false)

	# temp print
	var cardStr = []
	for card in cards:
		cardStr.append(StartVars.CardName(card))
	cardStr = StartVars.godot_sucks_join_array(cardStr, ", ")

	if LobbyConn.isMyTurn():
		# temp print
		print("I played %s" % cardStr)
	else:
		# temp print
		print("Player %s played %s" % [LobbyConn.Turn, cardStr])

func _on_turnended(cards): # cards automatically drawn
	# temp print
	var cardStr = []
	for card in cards:
		cardStr.append(StartVars.CardName(card))
	print("I finished my card by drawing %s" % StartVars.godot_sucks_join_array(cardStr, ", "))

func _on_gameover(player): # playerID winner
	get_tree().change_scene("res://scenes/lobby/Lobby.tscn")

func _on_playersupdated():
	fill_players_gameturn()

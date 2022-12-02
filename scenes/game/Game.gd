extends Node

#There might be a better way to do this but this is the only thing I found thro google
#We preload the image from files so we can use this variable is needeth beedeth
var button_empty = preload("res://assets/styles/button_empty.tres")
var button_empty2 = preload("res://assets/styles/button_empty2.tres")
var button_green = preload("res://assets/styles/button_green.tres")
var button_red = preload("res://assets/styles/button_red.tres")
var discardMode = false
var drawMode = false
var wanmo = false
var wanmo_hand = []
var combining = false
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
	var discard
	if StartVars.singlePlayer:
		cards = LobbySP.Cards
		discard = LobbySP.DiscardPile
	else:
		cards = LobbyConn.Cards
		discard = LobbyConn.DiscardPile

	$Background/DrawPileBox/CardRotate.setValue(discard)

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

#checks if current selected cards are a WANMO compatible hand
func wanmo_checker(hand):
	var fix_array = []
	#This fix array and sort basically just sorts the cards so I dont have to check 2 for each case
	for child in hand.size():
		fix_array += [int(hand[child])]
	fix_array.sort()
	
	#First check normal pairings
	if fix_array == [1,7] or fix_array == [9,11]  or fix_array ==  [3,5]:
		return true
	#This checks for free card placements
	elif fix_array == [1,14] or fix_array == [7,13] or fix_array == [1,12] or fix_array == [7,12] or fix_array == [9,12] or fix_array == [11,12] or fix_array == [11,14] or fix_array ==  [3,12] or fix_array ==  [5,13] or fix_array ==  [5,12]:
		return true
	else:
		return false

# Called when the node enters the scene tree for the first time.
func _ready():
	var fixpos = Vector2(-480,378)
	var fixsiz = Vector2(480,248)
	$TurnTransition/Box.set_position(fixpos)
	$TurnTransition/Box.set_size(fixsiz)
	$CardPlayed.hide()
	$TurnTransition.hide()
	$GameOver.hide()
	$Background/DrawnCard.connect("pressed_with_val", self, "_on_Card_pressed")
	$Background/DrawPileBox/CardRotate.connect("pressed_with_val", self, "_on_Card_pressed")
	$Background/DrawnCard.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	connect_signals()
	var fix = Vector2(176,100)
	$Background/DrawPileBox/CardRotate/Card.set_rotation(-PI)
	$Background/DrawPileBox/CardRotate/Card.flip_v = true
	$Background/DrawPileBox/CardRotate/Card.flip_h = true
	$Background/DrawPileBox/CardRotate/Card.set_position(fix)
	# update UI
	$Background/DrawnCard.hide()
	$Pause.hide()
	if StartVars.singlePlayer:
		$Pause/Panel/LobbyID.text = "Offline"
		$Pause/PlayerList/KickPlayer.hide()
	else:
		$Pause/Panel/LobbyID.text = "ID: %s" % LobbyConn.Code
	
	if !LobbyConn.isHost():
		$Pause/PlayerList/KickPlayer.hide()
		fix_display_message(true)
	
	if StartVars.singlePlayer:
		$Pause/PlayerList/KickPlayer.hide()
	
	fix_display_message2(true)
	fill_players_gameturn(true)
	fill_cards(false)
	$StartGame.show()
	$AnimationPlayer.play("StartGame_Transition")
		
func get_selected_cards():
	var selectedCards = []
	for child in $Background/HandBox.get_children():
		if child.selected:
			selectedCards.append(child.selfValue)
	return selectedCards

#This is for when a card is pressed, mainly validating a correct hand
func _on_Card_pressed(card):
	#first if we are in discard mode, then the selected card should be discarded
	if discardMode:
		print(LobbyConn.Cards)
		LobbyConn.discard(card.selfValue)
	#If we are in draw mode, then the selected card should be drawn
	#NOTE: the draw pile is not a card instance so that is accounted or elsewhere not here
	elif drawMode:
		if card.isDiscard:
			#LEave drawmode as we draw a card
			drawMode = false
			LobbyConn.draw(LobbyConn.DrawFrom.DISCARD)
			$Background/DrawPileBox/CardRotate.setValue(15)
			$Background/DrawPileBox/CardRotate/Card/darken.show()
			message_timer()
	#Else means we are selecting cards to play and must validate the hand
	else:
		#This first check just ensures they are selected something from their hand and not a different card on screen
		#We also check if we are in wanmo mode, which means a wanmo can be played
		if !card.isDrawnCard and !card.isDiscard and wanmo:
			#First, if clicked card is already selected
			if card.selected:
				#In wanmo mode, we check if a wanmo pair has been added, if not we loeave wanmo mode and deselect card
				if wanmo_hand.size() == 0:
					wanmo = false
					card.deselect()
					wanmo_hand = []
				#If a pair has been selected, we deselected all cards selected to not allow the player to play an invaild 3-card hand
				else:
					wanmo = false
					wanmo_hand = []
					for child in $Background/HandBox.get_children():
						child.deselect()
			#If card clicked isnt selected and can be, this means it is a valid wanmo pair
			elif card.canSelect:
				#First we select it, but next we need to find its valid wanmo pair from hand
				card.select()
				wanmo_hand+=[card]
				for child in $Background/HandBox.get_children():
					#This big if makes sure it finds an unselected matching pair, or a free card. 
					#NOTE: Currently this doesnt validate if the free card should work, but it might already get validated elsewhere --I believe it does
					#What i mean by validated elsewhere is that you cannot get to this point where the free card can be selected unless the free card is compatible with another card in hand
					if !child.selected and child.canSelect and (card.selfValue == child.selfValue or child.selfValue == 12 or child.selfValue == 13 or child.selfValue == 14):
						child.select()
						wanmo_hand+=[child]
						break
		#Now address non wanmo cases
		#If card is already selected we deselect it or vice versa
		elif !card.isDrawnCard and !card.isDiscard:
			if card.selected:
				card.deselect()
			elif card.canSelect:
				card.select()
				
		# get list of selected cards
		var selectedCards = get_selected_cards()
		#var selectedCards = [StartVars.Cards.Triangle2, StartVars.Cards.Circle2]
		
		#If selected cards is 2 then we check if its a valid wanmo hand
		if selectedCards.size() == 2:
			if wanmo_checker(selectedCards):
				wanmo= true
			else:
				wanmo= false
		# figure out which cards can be selected, returns null if no cards are selected
		var selectableCards = StartVars.getValidCards($Background/HandBox, selectedCards)
		
		if combining:
			selectableCards = StartVars.getValidCards($Background/HandBox, selectedCards)
			
		print("selectaben ",selectableCards)
		print("wanmo ", wanmo_hand)
		# loop through cards, if any do not exist within selectableCards, grey them out
		if !card.isDrawnCard and !card.isDiscard:
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
			current = 0
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

#This is when the play area is pressed to play cards
func _on_Submit_pressed():
	#Get selected cards
	var selectedCards = get_selected_cards()
	#First is the nonwanmo case
	if selectedCards.size() == 3:
		for child in selectedCards:
			if child != 12 or child != 13 or child != 14:
				message_timer2("Invaild hand, try another!")
				break
	if !discardMode and !drawMode and !wanmo:
		#If they attempt to play a lone card that isnt a free card we stop them
		if selectedCards.size() == 1 and (selectedCards[0] != 12 and selectedCards[0] != 13 and selectedCards[0] != 14 ): #12, 13, 14
			message_timer2()
			return
		#Otherwise play the free card/hand
		LobbyConn.play(selectedCards, null)
	#If a wanmo is at play
	elif !discardMode and !drawMode and wanmo:
		#This fixes the get selected cards ti not include the wanmo pair
		var fix_selectedCards = []
		#If you somehow got here without playing 4 cards I just allow the play
		if selectedCards.size() != 4:
			wanmo = false
			wanmo_hand = []
			LobbyConn.play(selectedCards, null)
		else:
			#I have to fix wanmo hand here because I need it formatted differently to send to the server woth .play
			#I dont do this before because it would break a lot of code I already have and im lazy
			wanmo_hand = [wanmo_hand[0].selfValue, wanmo_hand[1].selfValue]
			#Now we go through selkectedcards and only add cards to the fix_ if theyre not from the wanmo pairing
			for child in selectedCards:
				if child == wanmo_hand[0] or child == wanmo_hand[1]:
					pass
				else:
					fix_selectedCards += [child]
			print(fix_selectedCards,wanmo_hand)
			#I was feeling aggressive here
			print("loser",selectedCards)
			LobbyConn.play(fix_selectedCards, wanmo_hand)
			wanmo_hand = []

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
	
	#This is the only way I could get animations to work in the correct order
	#This yield is for animations in _on_cards_played()
	yield($AnimationPlayer, "animation_finished")
	if wanmo:
		$CardPlayed/WANMO.show()
		$AnimationPlayer.play("WANMO")
		yield($AnimationPlayer, "animation_finished")
		wanmo = false
	
	$TurnTransition.show()
	$StartGame.hide()
	$CardPlayed.hide()
	for child in $CardPlayed.get_children():
		child.hide()
	$AnimationPlayer.play("TurnTransition")
	yield($AnimationPlayer, "animation_finished")
	$TurnTransition.hide()
	
	if LobbyConn.isMyTurn():
		print("My turn")
		drawMode = true
		$Background/DrawPileBox/CardRotate/Card/darken.hide()
		message_timer()
	else:
		print("Player %s's turn" % player)

# from: DrawFrom.DRAW_FROM_DECK or DrawFrom.DRAW_FROM_DISCARD
# card will be null if it isnt your turn
func _on_carddrew(from, card):
	if LobbyConn.isMyTurn():
		$Background/DrawnCard.setValue(card)
		$Background/DrawnCard.setCanSelect(true)
		$Background/DrawnCard.show()
		print("I drew %s from %s" % [StartVars.CardName(card), LobbyConn.DrawFrom.keys()[from]])
		for child in $Background/HandBox.get_children():
			child.setCanSelect(true)
		discardMode = true
		message_timer()
	else:
		print("Player %s drew from %s" % [LobbyConn.Turn, LobbyConn.DrawFrom.keys()[from]])

func _on_carddiscarded(card):
	if LobbyConn.isMyTurn():
		print(LobbyConn.Cards)
		$Background/DrawnCard.hide()
		discardMode = false
		fill_cards(true)
		# temp print
		print("I discarded %s" % StartVars.CardName(card))
		message_timer()
	else:
		fill_cards(false)
		print("Player %s discarded %s" % [LobbyConn.Turn, StartVars.CardName(card)])

func _on_cardsplayed(handType, cards, wanmoPair): # cards will be null if passed
	#I use the servers identifier to determine the correct animation to play
	print("on card played ", handType, typeof(handType), typeof(LobbyConn.HandTypes.PASS))

	if handType == LobbyConn.HandTypes.PASS:
		print("Pass animation")
		$CardPlayed/Pass.show()
		$CardPlayed.show()
		$AnimationPlayer.play("Pass")
	elif handType == LobbyConn.HandTypes.PAIR:
		print("This should be a pair")
		$CardPlayed/P1C2/AnimCard.setValue(cards[0])
		$CardPlayed/P1C2/AnimCard2.setValue(cards[1])
		$CardPlayed.show()
		$CardPlayed/P1C2.show()
		$AnimationPlayer.play("P1C2")
	elif handType == LobbyConn.HandTypes.PAIR_INVERTED:
		print("This should be a pair inverted")
		$CardPlayed/P2C2/AnimCard.setValue(cards[0])
		$CardPlayed/P2C2/AnimCard2.setValue(cards[1])
		$CardPlayed.show()
		$CardPlayed/P2C2.show()
		$AnimationPlayer.play("P2C2")
	elif handType == LobbyConn.HandTypes.WANMO_BIG_PAIR:
		$CardPlayed/P3C21/AnimCard.setValue(cards[0])
		$CardPlayed/P3C21/AnimCard2.setValue(cards[1])
		$CardPlayed/WANMO/AnimCard.setValue(wanmoPair[0])
		$CardPlayed/WANMO/AnimCard2.setValue(wanmoPair[1])
		$CardPlayed.show()
		$CardPlayed/P3C21.show()
		$AnimationPlayer.play("P3C2-1")
	elif handType == LobbyConn.HandTypes.WANMO_DOUBLE_SHAPE_PAIR:
		$CardPlayed/P3C22/AnimCard.setValue(cards[0])
		$CardPlayed/P3C22/AnimCard2.setValue(cards[1])
		$CardPlayed/WANMO/AnimCard.setValue(wanmoPair[0])
		$CardPlayed/WANMO/AnimCard2.setValue(wanmoPair[1])
		$CardPlayed.show()
		$CardPlayed/P3C22.show()
		$AnimationPlayer.play("P3C2-2")
	elif handType == LobbyConn.HandTypes.SINGLEFREE:
		$CardPlayed/FreeCard1/AnimCard.setValue(cards[0])
		$CardPlayed.show()
		$CardPlayed/FreeCard1.show()
		$AnimationPlayer.play("FreeCard1")
	elif handType == LobbyConn.HandTypes.BIG_PAIR:
		$CardPlayed/P3C21/AnimCard.setValue(cards[0])
		$CardPlayed/P3C21/AnimCard2.setValue(cards[1])
		$CardPlayed.show()
		$CardPlayed/P3C21.show()
		$AnimationPlayer.play("P3C2-1")
	elif handType == LobbyConn.HandTypes.DOUBLE_SHAPE_PAIR:
		$CardPlayed/P3C22/AnimCard.setValue(cards[0])
		$CardPlayed/P3C22/AnimCard2.setValue(cards[1])
		$CardPlayed.show()
		$CardPlayed/P3C22.show()
		$AnimationPlayer.play("P3C2-2")
	elif handType == LobbyConn.HandTypes.DOUBLE_FREE:
		$CardPlayed/FreeCard2/AnimCard.setValue(cards[0])
		$CardPlayed/FreeCard2/AnimCard2.setValue(cards[1])
		$CardPlayed.show()
		$CardPlayed/FreeCard2.show()
		$AnimationPlayer.play("FreeCard2")
	elif handType == LobbyConn.HandTypes.TRIPLE_FREE:
		$CardPlayed/FreeCard3/AnimCard.setValue(cards[0])
		$CardPlayed/FreeCard3/AnimCard2.setValue(cards[1])
		$CardPlayed/FreeCard3/AnimCard3.setValue(cards[2])
		$CardPlayed.show()
		$CardPlayed/FreeCard3.show()
		$AnimationPlayer.play("FreeCard3")
	elif handType == LobbyConn.HandTypes.QUAD_FREE:
		$CardPlayed/FreeCard4/AnimCard.setValue(cards[0])
		$CardPlayed/FreeCard4/AnimCard2.setValue(cards[1])
		$CardPlayed/FreeCard4/AnimCard3.setValue(cards[2])
		$CardPlayed/FreeCard4/AnimCard4.setValue(cards[2])
		$CardPlayed.show()
		$CardPlayed/FreeCard4.show()
		$AnimationPlayer.play("FreeCard4")

	fill_cards(false)
	if LobbyConn.isMyTurn():
		# temp print
		message_timer()
	else:
		# temp print
		pass

func _on_turnended(cards): # cards automatically drawn
	# temp print
	var cardStr = []
	for card in cards:
		cardStr.append(StartVars.CardName(card))
	fix_display_message2(true)
	print("I finished my card by drawing %s" % StartVars.godot_sucks_join_array(cardStr, ", "))

func _on_gameover(player): # playerID winner
	#yield($AnimationPlayer, "animation_finished")
	LobbyConn.InLobby = true
	$TurnTransition.hide()
	$StartGame.hide()
	$CardPlayed.hide()
	$GameOver/Lose.hide()
	$GameOver.show()
	$GameOver/Win.show()
	$AnimationPlayer.play("Win_Screen")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/lobby/Lobby.tscn")

func _on_playersupdated():
	fill_players_gameturn()

#This is an automatic message timer that waits before telling player the predet message. See fix_display_message()
func message_timer():
	fix_display_message(true)
	yield(get_tree().create_timer(10),"timeout")
	fix_display_message()

func message_timer2(message = ""):
	fix_display_message2(false, message)
	yield(get_tree().create_timer(5),"timeout")
	fix_display_message2(true)
	

#This displays a predetermined message in the play area
func fix_display_message(override = false):
	#display guide text in play area
	if drawMode:
		$Background/PlayArea/DisplayMessage.text = "\nClick above to draw a card!"
	elif discardMode:
		$Background/PlayArea/DisplayMessage.text = "\n\nChoose a card to discard!"
	#Override removes the text without checking current mode
	elif override:
		$Background/PlayArea/DisplayMessage.text = ""
	else:
		$Background/PlayArea/DisplayMessage.text = "\nPick your cards, then click here to play them!"

func fix_display_message2(override = false, message = ""):
	#display guide text in play area
	if drawMode:
		$Background/DisplayMessage2.text = ""
	elif discardMode:
		$Background/DisplayMessage2.text = ""
	#Override removes the text without checking current mode
	elif override:
		$Background/DisplayMessage2.text = ""
	elif message != "":
		$Background/DisplayMessage2.text = message
	else:
		$Background/DisplayMessage2.text = "You can't play just one card! Play nothing to pass your turn."

func _on_DrawPile_pressed():
	#If we are drawing, draw from deck and show drawn card
	if drawMode:
		drawMode = false
		LobbyConn.draw(LobbyConn.DrawFrom.DECK)
		$Background/DrawPileBox/CardRotate/Card/darken.show()
		message_timer()

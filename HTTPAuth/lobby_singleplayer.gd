extends Node

var Players = []
var InLobby = true

var DiscardPile = -1
var Cards = []

# 2d array of cards for bots
var NonPlayerCards = []

var Points = []
var Turn = 0

var PointGoal = 17

# general
signal disconnected()

# in lobby
signal game_starting()

# in game
signal player_turn(player)
signal card_drew(from, card) # from: DrawFrom.DRAW_FROM_DECK or DrawFrom.DRAW_FROM_DISCARD
signal card_discarded(card)
signal cards_played(handType, cards, wanmoPair) # cards and wanmoPair will be null if passed
signal turn_ended(cards) # cards automatically drawn

signal game_over(playerID) # playerID winner

func isMyTurn():
	return Turn == 0

func getTurnIndex():
	return Turn

func resetVariables():
	Players = []
	InLobby = true
	DiscardPile = -1
	Cards = []
	NonPlayerCards = []
	Points = []
	Turn = 0

#Moved where this is to make lobby work
func _ready():
	Players = []
	Players.append(UserData.objFrom("Human", "Player", 25))
	for i in 3:
		Players.append(UserData.objFrom("Bot", str(i+1), 25))

func startGame():
	Cards = generateCardHand()
	NonPlayerCards = []
	for i in 3:
		NonPlayerCards.append(generateCardHand())
	emit_signal("game_starting")

func join_game():
	# TODO start turn loop
	# emit_signal("player_turn", state.turn)
	# if my turn
	#   emit_signal("turn_ended", cards)
	#   emit_signal("game_over", playerID)
	pass
		
func setPointGoal(goal):
	PointGoal = goal

func leave():
	resetVariables()
	emit_signal("disconnected")

func draw(from):
	var drew
	if from == LobbyConn.DrawFrom.DRAW_FROM_DECK:
		drew = RandomCard()
	elif from == LobbyConn.DrawFrom.DRAW_FROM_DISCARD:
		drew = DiscardPile
		DiscardPile = -1
	Cards += [drew]
	emit_signal("card_drew", from, drew)
		
func discard(card):
	DiscardPile = card
	emit_signal("card_discarded", card)
		
func play(cards, wanmoPair):
	if cards == null:
		emit_signal("cards_played", LobbyConn.HandTypes.PASS, null, null)
	else:
		pass
		# TODO play cards
		# calculate hand type
		# emit_signal("cards_played", type, cards, wanmoPair)

func generateCardHand():
	var cards = []
	for i in 5:
		cards.append(RandomCard())
	return cards

func RandomCard():
	# every individual card has an equal chance of being selected, except all forms of free card are counted as one
	randomize()
	var num = randi() % 13

	# is free card
	if num < 12:
		return num
	else:
		num = randi() % 4
		if num < 2:
			return StartVars.Cards.Free
		elif num == 2:
			return StartVars.Cards.CircleFree
		else:
			return StartVars.Cards.TriangleFree

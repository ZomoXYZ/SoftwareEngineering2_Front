extends Node

var Players = []
var InLobby = true

var DiscardPile = -1
var Cards = []

# 2d array of cards for bots
var NonPlayerCards = []

signal disconnected()
signal game_starting()

func initiate():
	Players = []
	for i in 3:
		Players.append(UserData.objFrom("Bot", str(i+1), 25))

func getAllPlayers():
	return [UserData.asObj()] + Players

func start():
	Cards = generateCardHand()
	NonPlayerCards = []
	for i in 3:
		NonPlayerCards.append(generateCardHand())
	emit_signal("game_starting")

func leave():
	emit_signal("disconnected")

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
		num = randi() % 3
		if num < 2:
			return StartVars.Card.Free
		elif num == 2:
			return StartVars.Card.CircleFree
		else:
			return StartVars.Card.TriangleFree

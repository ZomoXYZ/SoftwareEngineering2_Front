extends Node

var Players = []
var InLobby = true

signal disconnected()
signal game_starting()

func initiate():
	Players = []
	for i in 3:
		Players.append(UserData.objFrom("Bot", str(i+1), 25))

func getAllPlayers():
	return [UserData.asObj()] + Players

func start():
	emit_signal("game_starting")

func leave():
	emit_signal("disconnected")
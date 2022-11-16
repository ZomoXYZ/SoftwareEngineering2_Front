extends Control

#There might be a better way to do this but this is the only thing I found thro google
#We preload the image from files so we can use this variable is needeth beedeth
var button_empty = preload("res://assets/styles/button_empty.tres")
var button_green = preload("res://assets/styles/button_green.tres")
var button_red = preload("res://assets/styles/button_red.tres")

func connect_signals():
	if StartVars.singlePlayer:
		print("singleplayer")
		# singleplayer in the end will be a separate file with its own signals
		# we should be able to use it just like we use LobbyConn
	else:
		LobbyConn.connect("players_updated", self, "_on_players_updated")
		LobbyConn.connect("game_starting", self, "_on_game_starting")
		LobbyConn.connect("disconnected", self, "_on_disconnected")

# Called when the node enters the scene tree for the first time.
func _ready():
	connect_signals()

	if !LobbyConn.InLobby:
		_on_game_starting()
	
	#Check is single lobby or not
	fill_players()
		
	#Very important to make sure the transitions are hidden
	$StartGamePanel.hide()
	$LobbyOptions.hide()
	$OutroPanel.hide()
	
	if StartVars.isHost or StartVars.singlePlayer:
		$Background/Panel/Start.show()
	else:
		$Background/Panel/Start.hide()
		$Background/BottomBar/Options.disabled = true

	#intro animation
	$IntroPanel.show()
	$AnimationPlayer.play("Intro_Transition")
	yield($AnimationPlayer, "animation_finished")
	$IntroPanel.hide()

func generate_bot_data():
	var bot_data = []
	for i in 3:
		bot_data.append(UserData.objFrom("Bot", str(i+1), 25))
	return bot_data

func fill_players():
	# variables
	var players = []
	var code = ""

	# fill variables
	if StartVars.singlePlayer:
		players = [UserData.asObj()] + generate_bot_data()
		code = "1234"
	else:
		players = [LobbyConn.Host] + LobbyConn.players
		code = LobbyConn.Code
		
	# show lobby code
	$Background/Panel/LobbyID.text = "ID: %s" % code

	# fill player list
	for i in 4:
		var current = $Background/PlayerList.get_child(i)
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

func _on_players_updated():
	fill_players()

#Starting starts the game
func _on_Start_pressed():
	if StartVars.singlePlayer:
		_on_game_starting()
	elif StartVars.isHost:
		LobbyConn.send("start")

func _on_game_starting():
	$StartGamePanel.show()
	$IntroPanel.hide()
	#Standard animation procedure
	$AnimationPlayer.play("StartGame_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/game/Game.tscn")

#returns to main menu if you were in single player, and returns to lobby list is from multiplayuer
func _on_Leave_pressed():
	if StartVars.singlePlayer:
		_on_disconnected()
	else:
		LobbyConn.leave()

#Shows the options overlay menu
func _on_Options_pressed():
	#Hide into panel here in case the button gets pressed during the intro animation
	$IntroPanel.hide()
	#Standard animation procedure
	$LobbyOptions.show()
	$AnimationPlayer.play("Options_Transition")
	yield($AnimationPlayer, "animation_finished")

#Hides overlay when done with options menu
func _on_BackToLobby_pressed():
	#Hide into panel here in case the button gets pressed during the intro animation
	$IntroPanel.hide()
	#Standard animation procedure
	$AnimationPlayer.play_backwards("Options_Transition")
	yield($AnimationPlayer, "animation_finished")
	$LobbyOptions.hide()

func _on_disconnected():
	#Hide into panel here in case the button gets pressed during the intro animation
	#Also hide bottom bar to ensure the playter cant inturrupt the animation
	$IntroPanel.hide()
	$Background/BottomBar.hide()
	#Standard animation procedure
	$OutroPanel.show()
	$AnimationPlayer.play("Leave_Transition")
	yield($AnimationPlayer, "animation_finished")
	#Then check which screen to return to
	
	StartVars.isHost = false

	if StartVars.singlePlayer:
		StartVars.singlePlayer = false
		get_tree().change_scene("res://scenes/main_menu/Main_Menu.tscn")
	else:
		get_tree().change_scene("res://scenes/lobby_list/Lobby_List.tscn")

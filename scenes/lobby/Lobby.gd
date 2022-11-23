extends Control

#There might be a better way to do this but this is the only thing I found thro google
#We preload the image from files so we can use this variable is needeth beedeth
var button_empty = preload("res://assets/styles/button_empty.tres")
var button_green = preload("res://assets/styles/button_green.tres")
var button_red = preload("res://assets/styles/button_red.tres")

var animating = false

func connect_signals():
	if StartVars.singlePlayer:
		LobbySP.connect("game_starting", self, "_on_game_starting")
		LobbySP.connect("disconnected", self, "_on_disconnected")
	else:
		LobbyConn.connect("players_updated", self, "_on_players_updated")
		LobbyConn.connect("game_starting", self, "_on_game_starting")
		LobbyConn.connect("disconnected", self, "_on_disconnected")

		# just in case we missed the signal
		if !LobbyConn.InLobby:
			_on_game_starting()

# Called when the node enters the scene tree for the first time.
func _ready():
	connect_signals()
	
	#Check is single lobby or not
	fill_players()
		
	#Very important to make sure the transitions are hidden
	$StartGamePanel.hide()
	$LobbyOptions.hide()
	$OutroPanel.hide()
	
	if StartVars.singlePlayer or LobbyConn.isHost():
		$Background/Panel/Start.show()
	else:
		$Background/Panel/Start.hide()
		$Background/BottomBar/Options.disabled = true

	#intro animation
	$IntroPanel.show()
	$AnimationPlayer.play("Intro_Transition")
	animating = true
	yield($AnimationPlayer, "animation_finished")
	animating = false
	$IntroPanel.hide()

func fill_players():
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
	$Background/Panel/LobbyID.text = codeText

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
		LobbySP.start()
	else:
		LobbyConn.send("start")

func _on_game_starting():
	$StartGamePanel.show()
	$IntroPanel.hide()
	#Standard animation procedure
	$AnimationPlayer.play("StartGame_Transition")
	animating = true
	yield($AnimationPlayer, "animation_finished")
	animating = false
	get_tree().change_scene("res://scenes/game/Game.tscn")

#returns to main menu if you were in single player, and returns to lobby list is from multiplayuer
func _on_Leave_pressed():
	if !animating:
		if StartVars.singlePlayer:
			LobbySP.leave()
		else:
			LobbyConn.leave()

#Shows the options overlay menu
func _on_Options_pressed():
	if !animating:
		#Hide into panel here in case the button gets pressed during the intro animation
		$IntroPanel.hide()
		#Standard animation procedure
		$LobbyOptions.show()
		$AnimationPlayer.play("Options_Transition")
		yield($AnimationPlayer, "animation_finished")

#Hides overlay when done with options menu
func _on_BackToLobby_pressed():
	if !animating:
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

	if StartVars.singlePlayer:
		StartVars.singlePlayer = false
		get_tree().change_scene("res://scenes/main_menu/Main_Menu.tscn")
	else:
		get_tree().change_scene("res://scenes/lobby_list/Lobby_List.tscn")

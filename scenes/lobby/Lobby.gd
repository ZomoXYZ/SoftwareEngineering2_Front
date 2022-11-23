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
	$LobbyOptions/Panel/LineEdit.hide()
	$LobbyOptions/Panel/BackForText.hide()
	
	if StartVars.singlePlayer or LobbyConn.isHost():
		$Background/Panel/Start.show()
		if StartVars.singlePlayer:
			$LobbyOptions/Panel/ButtonContainer/KickPlayer.set_disabled(true)
			$LobbyOptions/Panel/ButtonContainer/SetPassword.set_disabled(true)
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

#Options menu options

func _on_SetPassword_pressed():
	#setup our textbox when button pressed
	var pos = Vector2($LobbyOptions/Panel/ButtonContainer/SetPassword.rect_position.x,$LobbyOptions/Panel/ButtonContainer/SetPassword.rect_position.y+220)
	$LobbyOptions/Panel/LineEdit.clear()
	$LobbyOptions/Panel/LineEdit.set_position(pos)
	$LobbyOptions/Panel/LineEdit.placeholder_text = "Enter Pass Here"
	$LobbyOptions/Panel/LineEdit.show()
	$LobbyOptions/Panel/BackForText.show()
	$LobbyOptions/Panel/LineEdit.grab_focus()


func _on_KickPlayer_pressed():
	pass # Replace with function body.


func _on_PointGoal_pressed():
	#setup our textbox when button pressed
	var pos = Vector2($LobbyOptions/Panel/ButtonContainer/PointGoal.rect_position.x,$LobbyOptions/Panel/ButtonContainer/PointGoal.rect_position.y+220)
	$LobbyOptions/Panel/LineEdit.clear()
	$LobbyOptions/Panel/LineEdit.set_position(pos)
	#Note Change placeholder text here to the current point goal
	$LobbyOptions/Panel/LineEdit.placeholder_text = 'Try "20"'
	$LobbyOptions/Panel/LineEdit.show()
	$LobbyOptions/Panel/BackForText.show()
	$LobbyOptions/Panel/LineEdit.grab_focus()


func _on_LineEdit_text_entered(code):
	$LobbyOptions/Panel/LineEdit.hide()
	#Will need to check position to determine which textbox this is functioning as to send correct signal

func _on_LineEdit_text_changed(new_text):
	var old_caret_position = $LobbyOptions/Panel/LineEdit.caret_position
	var word = ''
	var regex = RegEx.new()
	#Checks to see which textbox it is before restricting characters
	if $LobbyOptions/Panel/LineEdit.placeholder_text == 'Try "20"':
		regex.compile("[0-9]")
	else:
		regex.compile("[A-Z]|[0-9]")
	for valid_character in regex.search_all(new_text.to_upper()):
		word += valid_character.get_string()
	$LobbyOptions/Panel/LineEdit.set_text(word)
	$LobbyOptions/Panel/LineEdit.caret_position = old_caret_position

func _on_BackForText_pressed():
	#This hides the textbox for clicking out
	$LobbyOptions/Panel/LineEdit.hide()
	$LobbyOptions/Panel/BackForText.hide()

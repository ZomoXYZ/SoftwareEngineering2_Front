extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#There might be a better way to do this but this is the only thing I found thro google
#We preload the image from files so we can use this variable is needeth beedeth
var button_empty = preload("res://assets/styles/button_empty.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	#Check is single lobby or not
	if StartVars.singlePlayer:
		#If single player I went ahead and set bots and changed the lobby ID to offline
		$Background/Panel/LobbyID.text = "Offline"
		$Background/PlayerList/Player2.text = "Easy \nBot "
		$Background/PlayerList/Player3.text = "Medium \nBot "
		$Background/PlayerList/Player4.text = "Hard \nBot "
	else:
		#If online, then I set all the other players slots to empty and hid their playerIcons
		$Background/Panel/LobbyID.text = "ID: 123456"
		$Background/PlayerList/Player2.add_stylebox_override("normal", button_empty)
		$Background/PlayerList/Player2.text = ""
		$Background/PlayerList/Player2/PlayerIcon.hide()
		$Background/PlayerList/Player3.add_stylebox_override("normal", button_empty)
		$Background/PlayerList/Player3.text = ""
		$Background/PlayerList/Player3/PlayerIcon.hide()
		$Background/PlayerList/Player4.add_stylebox_override("normal", button_empty)
		$Background/PlayerList/Player4.text = ""
		$Background/PlayerList/Player4/PlayerIcon.hide()
		
	#Very important to make sure the transitions are hidden
	$StartGamePanel.hide()
	$LobbyOptions.hide()
	$OutroPanel.hide()
	#We show the intro and play the animation then hide the intro
	$IntroPanel.show()
	$AnimationPlayer.play("Intro_Transition")
	yield($AnimationPlayer, "animation_finished")
	$IntroPanel.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#Starting starts the game
func _on_Start_pressed():
	#Hide into panel here in case the button gets pressed during the intro animation
	$IntroPanel.hide()
	#Standard animation procedure
	$StartGamePanel.show()
	$AnimationPlayer.play("StartGame_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/game/Game.tscn")

#returns to main menu if you were in single player, and returns to lobby list is from multiplayuer
func _on_Leave_pressed():
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

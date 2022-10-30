extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	if StartVars.singlePlayer:
		$Background/Panel/LobbyID.text = "Offline"
	else:
		$Background/Panel/LobbyID.text = "ID: 123456"
	$IntroPanel.show()
	$LobbyOptions.hide()
	$AnimationPlayer.play("Intro_Transition")
	yield($AnimationPlayer, "animation_finished")
	$IntroPanel.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#Starting starts the game
func _on_Start_pressed():
	$IntroPanel.hide()
	get_tree().change_scene("res://scenes/game/Game.tscn")

#returns to main menu if you were in single player, and returns to lobby list is from multiplayuer
func _on_Leave_pressed():
	$IntroPanel.hide()
	if StartVars.singlePlayer:
		StartVars.singlePlayer = false
		get_tree().change_scene("res://scenes/main_menu/Main_Menu.tscn")
	else:
		get_tree().change_scene("res://scenes/lobby_list/Lobby_List.tscn")

#Shows the options overlay menu
func _on_Options_pressed():
	$IntroPanel.hide()
	$LobbyOptions.show()
	$AnimationPlayer.play("Options_Transition")
	yield($AnimationPlayer, "animation_finished")

#Hides overlay when done with options menu
func _on_BackToLobby_pressed():
	$IntroPanel.hide()
	$AnimationPlayer.play_backwards("Options_Transition")
	yield($AnimationPlayer, "animation_finished")
	$LobbyOptions.hide()

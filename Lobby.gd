extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$LobbyOptions.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#Starting starts the game
func _on_Start_pressed():
	get_tree().change_scene("res://Game.tscn")

#returns to main menu if you were in single player, and returns to lobby list is from multiplayuer
func _on_Leave_pressed():
	if StartVars.singlePlayer:
		StartVars.singlePlayer = false
		get_tree().change_scene("res://Main_Menu.tscn")
	else:
		get_tree().change_scene("res://Lobby_List.tscn")

#Shows the options overlay menu
func _on_Options_pressed():
	$LobbyOptions.show()

#Hides overlay when done with options menu
func _on_BackToLobby_pressed():
	$LobbyOptions.hide()

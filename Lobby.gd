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


func _on_Start_pressed():
	get_tree().change_scene("res://Game.tscn")


func _on_Leave_pressed():
	get_tree().change_scene("res://Lobby_List.tscn")


func _on_Options_pressed():
	$LobbyOptions.show()


func _on_BackToLobby_pressed():
	$LobbyOptions.hide()

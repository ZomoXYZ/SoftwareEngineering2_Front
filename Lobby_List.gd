extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	HTTPAuth.createRequest(self, "_on_get_lobbylyst", "/lobbylist")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#Return to main menu
func _on_To_Main_Menu_pressed():
	get_tree().change_scene("res://Main_Menu.tscn")

#Goes to the lobby screen to create a lobby
func _on_CreateLobby_pressed():
	get_tree().change_scene("res://Lobby.tscn")

func _on_get_lobbylyst(result, _response_code, _headers, body):
	if HTTPAuth.verifyRequest(result) != HTTPAuth.Status.Online:
		return

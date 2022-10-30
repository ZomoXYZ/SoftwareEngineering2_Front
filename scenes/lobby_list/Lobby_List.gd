extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	# temp online checker
	# TODO make a better online check system
	# my vote is to not allow this page to be acceessed at all
	if Request.token != "":
		Request.createRequest(self, "_on_get_lobbylyst", "/lobbylist")
		
	#Standard animation procedure
	$IntroPanel.show()
	$AnimationPlayer.play("Intro_Transition")
	yield($AnimationPlayer, "animation_finished")
	#Hide all animation objects
	$IntroPanel.hide()
	$OutroPanel.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#Return to main menu
func _on_To_Main_Menu_pressed():
	#Standard animation procedure
	$OutroPanel.show()
	$AnimationPlayer.play("Outro_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/main_menu/Main_Menu.tscn")

#Goes to the lobby screen to create a lobby
func _on_CreateLobby_pressed():
	#Standard animation procedure
	$OutroPanel.show()
	$AnimationPlayer.play("Outro_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/lobby/Lobby.tscn")

func _on_get_lobbylyst(result, response_code, _headers, bodyString):
	var response = Request.parseResponse(result, response_code, bodyString)
	if response[0] != Request.Status.Online || response[1] == null:
		return
	var lobbylist = response[1]
	print(lobbylist)

extends Control

export(PackedScene) var lobbyButtonScene
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var remember = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	LobbyConn.connect("joined_lobby", self, "_lobby_joined")
	Request.createRequest(self, "_on_get_lobbylyst", "/lobbylist")
	#Standard animation procedure
	$IntroPanel.show()
	$AnimationPlayer.play("Intro_Transition")
	yield($AnimationPlayer, "animation_finished")
	#Hide all animation objects
	$Background/TopButtons/JoinbyID/LineEdit.hide()
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
	if Request.token != "":
		Request.createRequest(self, "_on_Lobby_created", "/lobby", HTTPClient.METHOD_POST)
	

func _on_Lobby_created(result, response_code, _headers, bodyString):
	# parse response
	var response = Request.parseResponse(result, response_code, bodyString)
	if response[0] != Request.Status.Online || response[1] == null:
		return
	var lobbydata = response[1]
	
	LobbyConn.join(lobbydata['id'])

func _on_get_lobbylyst(result, response_code, _headers, bodyString):
	# parse response
	var response = Request.parseResponse(result, response_code, bodyString)
	#print(bodyString.get_string_from_utf8())
	if response[0] != Request.Status.Online || response[1] == null:
		return
	var lobbylist = response[1]
	
	# display buttons
	var lobbyButton
	for lobby in lobbylist['lobbies']:
		lobbyButton = lobbyButtonScene.instance()
		lobbyButton.code = lobby['code']
		lobbyButton.id = lobby['id']
		$Background/Lobbies.add_child(lobbyButton)
	remember = 50 * $Background/Lobbies.get_child_count()
	$Background/VSlider.max_value = remember
	$Background/VSlider.value = remember
	
func _on_get_lobbylystcode(result, response_code, _headers, bodyString):
	# parse response
	var response = Request.parseResponse(result, response_code, bodyString)
	#print(bodyString.get_string_from_utf8())
	if response[0] != Request.Status.Online || response[1] == null:
		return
	var lobbyid = response[1].id
	LobbyConn.join(lobbyid)

func _on_VSlider_value_changed(value):
	var current
	var vector
	var temp = value
	value = remember-value
	remember = temp
	for child in $Background/Lobbies.get_child_count():
		current = $Background/Lobbies.get_child(child)
		vector = current.get_position()
		current.set_position(Vector2(0,vector.y - value))
		
		
func _lobby_joined():
	# Standard animation procedure
	$OutroPanel.show()
	$AnimationPlayer.play("Outro_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/lobby/Lobby.tscn")

func _on_JoinbyID_pressed():
	print("hi")
	$Background/TopButtons/JoinbyID/LineEdit.show()
	
func _on_LineEdit_text_entered(code):
	$Background/TopButtons/JoinbyID/LineEdit.hide()
	Request.createRequest(self, "_on_get_lobbylystcode", "/lobby/%s" %code)

func _on_LineEdit_text_changed(text):
	pass


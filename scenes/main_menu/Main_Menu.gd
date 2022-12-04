extends Node

export(PackedScene) var triangleScene
export(PackedScene) var ellipseScene
export(PackedScene) var pfpbutton

var counter = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Request.connect("user_online", self, "_on_user_online")
	Request.connect("user_offline", self, "_on_user_offline")
	UserData.connect("user_updated", self, "_on_user_updated")
	var fixpos = Vector2(93,297)
	var fixsiz = Vector2(295,439)
	Request.authorizeSession()
	$CanvasLayer/ButtonContainer.set_position(fixpos)
	$CanvasLayer/ButtonContainer.set_size(fixsiz)

	# if already online, assume we're still online until told otherwise
	if Request.online:
		_on_user_online()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#goes straight to lobby
func _on_Singleplayer_pressed():
	Input.vibrate_handheld(50)
	#Using start vars as a flag to make sure our lobbies oriten themselves right
	StartVars.singlePlayer = true
	#Play animation before switching scene
	$AnimationPlayer.play("SinglePlayer_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/lobby/Lobby.tscn")

#Goes to lobby list
func _on_Multiplayer_pressed():
	Input.vibrate_handheld(50)
	$AnimationPlayer.play("MultiPlayer_Transition2")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/lobby_list/Lobby_List.tscn")


func _on_Tutorial_pressed():
	Input.vibrate_handheld(50)
	$AnimationPlayer.play("Unused_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/tutorial/Tutorial.tscn")


func _on_Credits_pressed():
	Input.vibrate_handheld(50)
	$AnimationPlayer.play("Unused_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://scenes/credits/Credits.tscn")

#Function for creating the background effect shapes
#Code vaguely stolen from here: https://docs.godotengine.org/en/stable/getting_started/first_2d_game/05.the_main_game_scene.html
func _on_EffectTimer_timeout():
	var shape
	#Randomly chooses between a circle and an ellipse
	if rand_range(0, 2) > 1:
		shape = triangleScene.instance()
	else:
		shape = ellipseScene.instance()
		
	# Choose a random location on Path2D.
	var shapeSpawnLocation = get_node("ShapePath/ShapeSpawnLocation")
	shapeSpawnLocation.offset = randi()

	# Set the shape's direction perpendicular to the path direction.
	var direction = shapeSpawnLocation.rotation + PI / 2

	# Set the shape's position to a random location.
	shape.position = shapeSpawnLocation.position

	# Add some randomness to the direction.
	direction += rand_range(-PI / 4, PI / 4)
	shape.rotation = direction

	# Choose the velocity for the shape.
	var velocity = Vector2(rand_range(150.0, 1000.0), 0.0)
	shape.linear_velocity = velocity.rotated(direction)

	# Spawn the shape by adding it to the Main scene.
	$ShapeHolder.add_child(shape)

func _on_user_online():
	print("User Online, Name: %s %s, Picture: %s" % [UserData.PlayerNameAdjective, UserData.PlayerNameNoun, UserData.PlayerPicture])
	print("User Online, Name: %s %s, Picture: %s" % [UserData.getMyAdjective(), UserData.getMyNoun(), UserData.PlayerPicture])
	$Background/ConfigMenu/Adjective.text = UserData.getMyAdjective()
	$Background/ConfigMenu/Noun.text = UserData.getMyNoun()
	var pfp = str(RequestEnv.BASE_URL) + str(UserData.getMyPicture())
	print(pfp)
	$CanvasLayer/ButtonContainer/Multiplayer.set_disabled(false)
	
	Request.createRequest(self, "_http_request_completed", UserData.getMyPicture())
	#Request.createRequest(self, "_http_request_completed2", UserData.getPicture(0))
	for key in UserData.PictureList:
		Request.createRequest(self, "_http_request_completed2", UserData.getPicture(key))

# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	if image_error != OK:
		print("An error occurred while trying to display the image.")

	var texture = ImageTexture.new()
	texture.create_from_image(image)

	# Assign to the child TextureRect node
	$Background/ConfigMenu/Picture.texture = texture

func _http_request_completed2(result, response_code, headers, body):
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	var size = Vector2(40,40)
	var pos = Vector2(0,0)
	var pfp = pfpbutton.instance()
	if image_error != OK:
		print("An error occurred while trying to display the image.")

	var texture = ImageTexture.new()
	texture.create_from_image(image)
	pfp.set_texture(texture)
	pfp.set_size(size)
	#pfp.set_position(pos)
	
	# Assign to the child TextureRect node
	$Background/ConfigMenu/pfps.get_child(counter).add_child(pfp)
	#for child in $Background/ConfigMenu/pfps:
	#	child.set_size(size)
	#$Background/ConfigMenu/pfps.get_child(counter).get_child(-1).texture_normal = texture

func _on_user_offline():
	print("User Offline")
	$CanvasLayer/ButtonContainer/Multiplayer.set_disabled(true)

func _on_Adjective_pressed():
	UserData.setUserAdj(StartVars.randomIntKey(UserData.NameAdjectiveList, UserData.PlayerNameAdjective))

func _on_Noun_pressed():
	UserData.setUserNoun(StartVars.randomIntKey(UserData.NameNounList, UserData.PlayerNameNoun))

func _on_user_updated():
	$Background/ConfigMenu/Noun.text = "%s" %UserData.getMyNoun()
	$Background/ConfigMenu/Adjective.text = "%s" %UserData.getMyAdjective()

func _on_Config_pressed():
	print("hello %s %s aka %s %s" % [UserData.PlayerNameAdjective, UserData.PlayerNameNoun, UserData.getAdjective(UserData.PlayerNameAdjective), UserData.getNoun(UserData.PlayerNameNoun)])
	if $CanvasLayer.is_visible():
		$CanvasLayer.hide()
		$Logo.hide()
		$ShapeHolder.hide()
		$Background/ConfigMenu.show()
	else:
		$CanvasLayer.show()
		$Logo.show()
		$ShapeHolder.show()
		$Background/ConfigMenu.hide()

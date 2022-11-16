extends Node

@export var triangleScene: PackedScene
@export var ellipseScene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	Request.connect("user_online",Callable(self,"_on_user_online"))
	Request.connect("user_offline",Callable(self,"_on_user_offline"))
	Request.authorizeSession()

	# if already online, assume we're still online until told otherwise
	if Request.online:
		_on_user_online()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#goes straight to lobby
func _on_Singleplayer_pressed():
	#Using start vars as a flag to make sure our lobbies oriten themselves right
	StartVars.singlePlayer = true
	StartVars.isHost = true
	#Play animation before switching scene
	$AnimationPlayer.play("SinglePlayer_Transition")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/lobby/Lobby.tscn")

#Goes to lobby list
func _on_Multiplayer_pressed():
	$AnimationPlayer.play("MultiPlayer_Transition2")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/lobby_list/Lobby_List.tscn")


func _on_Tutorial_pressed():
	pass # Replace with function body.


func _on_Credits_pressed():
	$AnimationPlayer.play("Unused_Transition")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/credits/Credits.tscn")

#Function for creating the background effect shapes
#Code vaguely stolen from here: https://docs.godotengine.org/en/stable/getting_started/first_2d_game/05.the_main_game_scene.html
func _on_EffectTimer_timeout():
	var shape
	#Randomly chooses between a circle and an ellipse
	if randf_range(0, 2) > 1:
		shape = triangleScene.instantiate()
	else:
		shape = ellipseScene.instantiate()
		
	# Choose a random location checked Path2D.
	var shapeSpawnLocation = get_node("ShapePath/ShapeSpawnLocation")
	randomize()
	shapeSpawnLocation.progress_ratio = randf()

	# Set the shape's direction perpendicular to the path direction.
	var direction = shapeSpawnLocation.rotation + PI / 2

	# Set the shape's position to a random location.
	shape.position = shapeSpawnLocation.position

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	shape.rotation = direction

	# Choose the velocity for the shape.
	var velocity = Vector2(randf_range(150.0, 1000.0), 0.0)
	shape.linear_velocity = velocity.rotated(direction)

	# Spawn the shape by adding it to the Main scene.
	add_child(shape)

func _on_user_online():
	print("User Online, Name: %s %s, Picture: %s" % [UserData.PlayerNameAdjective, UserData.PlayerNameNoun, UserData.PlayerPicture])
	$UserInfo/Adjective.text = "%s" % UserData.PlayerNameAdjective
	$UserInfo/Noun.text = "%s" % UserData.PlayerNameNoun
	$UserInfo/Picture.text = "%s" % UserData.PlayerPicture
	$ButtonCenter/ButtonContainer/Multiplayer.set_disabled(false)

func _on_user_offline():
	print("User Offline")
	$Background/CanvasLayer/ButtonContainer/Multiplayer.set_disabled(true)

func _on_Adjective_pressed():
	var rand = randi() % 80 + 10
	UserData.setUserAdj(rand)
	$Background/Adjective.text = "%s" %rand


func _on_Noun_pressed():
	var rand = randi() % 80 + 10
	UserData.setUserNoun(rand)
	$Background/Noun.text = "%s" %rand

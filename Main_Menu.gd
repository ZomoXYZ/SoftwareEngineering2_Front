extends Node

export(PackedScene) var triangleScene
export(PackedScene) var ellipseScene

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	Request.authorizeSession()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#goes straight to lobby
func _on_Singleplayer_pressed():
	StartVars.singlePlayer = true
	$AnimationPlayer.play("SinglePlayer_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://Lobby.tscn")

#Goes to lobby list
func _on_Multiplayer_pressed():
	$AnimationPlayer.play("MultiPlayer_Transition")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://Lobby_List.tscn")


func _on_Tutorial_pressed():
	pass # Replace with function body.


func _on_Credits_pressed():
	pass # Replace with function body.

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
	add_child(shape)

extends Node

export(PackedScene) var cardScene


# Called when the node enters the scene tree for the first time.
func _ready():
	var cardInstance
	$Pause.hide()
	for i in 5:
		cardInstance = cardScene.instance()
		cardInstance.set_rotation(PI / 2)
		$Background/HandBox.add_child(cardInstance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_PauseButton_pressed():
	$Pause.show()


func _on_Resume_pressed():
	$Pause.hide()


func _on_Leave_pressed():
	get_tree().change_scene("res://Lobby_List.tscn")

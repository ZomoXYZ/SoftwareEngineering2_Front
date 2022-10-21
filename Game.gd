extends Node

export(PackedScene) var cardScene


# Called when the node enters the scene tree for the first time.
func _ready():
	var cardInstance
	for i in 5:
		cardInstance = cardScene.instance()
		
		get_node('Background/HandBox').add_child(cardInstance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

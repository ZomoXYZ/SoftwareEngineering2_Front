extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Singleplayer_pressed():
	pass # Replace with function body.

#Goes to lobby list
func _on_Multiplayer_pressed():
	$AnimationPlayer.play("Screen_Transition2")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene("res://Lobby_List.tscn")


func _on_Tutorial_pressed():
	pass # Replace with function body.


func _on_Credits_pressed():
	pass # Replace with function body.

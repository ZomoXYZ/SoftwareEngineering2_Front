extends Node

#Terrible way to do this yet alas
var cards = [
	'assets/sprites/cards/2Circ.png',
	'assets/sprites/cards/2Circ2Trig.png',
	'assets/sprites/cards/2Trig.png',
	'assets/sprites/cards/2Trig2Circ.png',
	'assets/sprites/cards/Circ.png',
	'assets/sprites/cards/CircTrig.png',
	'assets/sprites/cards/FreeCard.png',
	'assets/sprites/cards/GreenFreeCard.png',
	'assets/sprites/cards/Inv2Circ.png',
	'assets/sprites/cards/Inv2Trig.png',
	'assets/sprites/cards/InvCirc.png',
	'assets/sprites/cards/InvTrig.png',
	'assets/sprites/cards/RedFreeCard.png',
	'assets/sprites/cards/Trig.png',
	'assets/sprites/cards/TrigCirc.png',
]

# Called when the node enters the scene tree for the first time.
func _ready():
	var type
	randomize()
	var rand = randi() % 15
	match rand:
		1:
			type = "2Circ"
		2:
			type = "2Circ2Trig"
		3:
			type = "2Trig"
		4:
			type = "2Trig2Circ"
		5:
			type = "Circ"
		6:
			type = "CircTrig"
		7:
			type = "FreeCard"
		8:
			type = "GreenFreeCard"
		9:
			type = "Inv2Circ"
		10:
			type = "Inv2Trig"
		11:
			type = "InvCirc"
		12:
			type = "InvTrig"
		13:
			type = "RedFreeCard"
		14:
			type = "Trig"
		0:
			type = "TrigCirc"
	
	$Card.texture_normal = load("assets/sprites/cards/%s.png" % type)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

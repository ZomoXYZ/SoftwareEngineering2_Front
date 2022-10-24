extends TextureButton


#Terrible way to do this yet alas
var cards = ['assets/sprites/cards/2Circ.png',
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
			 'assets/sprites/cards/TrigCirc.png',]

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#This will probably need to be changed later for server integration
	var card = cards[randi() % cards.size()]
	self.texture_normal = load(card)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

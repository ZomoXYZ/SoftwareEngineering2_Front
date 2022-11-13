extends Node

enum Cards {
	Circle1
	Circle2
	CircleInverted1
	CircleInverted2

	CircleTriangle1
	CircleTriangle2

	CircleFree

	Triangle1
	Triangle2
	TriangleInverted1
	TriangleInverted2

	TriangleCircle1
	TriangleCircle2

	TriangleFree

	Free

	Back # will never receive this from the server
}

var CardValue = -1

# CardAsset(Cards.Circle1)
func CardAsset(card):
	var cardName = Cards.keys()[card]
	return "assets/sprites/cards/%s.png" % cardName

# Called when the node enters the scene tree for the first time.
func _ready():
	if (CardValue == -1):
		print("CARD VALUE NOT SET")
	$Card.texture_normal = load(CardAsset(CardValue))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

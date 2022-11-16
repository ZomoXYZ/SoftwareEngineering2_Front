extends Node

#Signal because godot signal stummy upid
signal pressed_with_val(val)

enum Cards {
	Circle1
	Circle2
	CircleInverted1
	CircleInverted2

	CircleTriangle1
	CircleTriangle2

	Triangle1
	Triangle2
	TriangleInverted1
	TriangleInverted2

	TriangleCircle1
	TriangleCircle2

	Free
	CircleFree
	TriangleFree

	Back # will never receive this from the server
}

var selfValue = -1
var selected = false

func selfName():
	return CardName(selfValue)

# CardAsset(Cards.Circle1)
func CardAsset(card):
	var cardName = Cards.keys()[card]
	return "assets/sprites/cards/%s.png" % cardName

# CardName(Cards.Circle1)
func CardName(card):
	return Cards.keys()[card]

# CardValue("Circle1")
func CardValue(name):
	return Cards.get(name)

# Called when the node enters the scene tree for the first time.
func _ready():
	if (selfValue == -1):
		print("CARD VALUE NOT SET")
	$Card.texture_normal = load(CardAsset(selfValue))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Card_pressed():
	emit_signal("pressed_with_val", self)

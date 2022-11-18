extends Node

var selfValue = -1

var selected = false
var canSelect = true

export var isDiscard = false

#Signal because godot signal stummy upid
signal pressed_with_val(val)

func select():
	if selected:
		return
	selected = true
	var pos = $Card.get_position()
	pos.y -= 30
	$Card.set_position(pos)

func deselect():
	if !selected:
		return
	selected = false
	var pos = $Card.get_position()
	pos.y += 30
	$Card.set_position(pos)

func setCanSelect(can):
	canSelect = can
	if canSelect:
		$Card/darken.hide()
	else:
		$Card/darken.show()

func selfName():
	return StartVars.CardName(selfValue)

func _ready():
	if !isDiscard:
		if (selfValue == -1):
			print("CARD VALUE NOT SET")
		$Card.texture_normal = load(StartVars.CardAsset(selfValue))
	else:
		self.rect_rotation = -90
		print("please help me")

func _on_Card_pressed():
	emit_signal("pressed_with_val", self)

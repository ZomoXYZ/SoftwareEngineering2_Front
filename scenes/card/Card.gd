extends Node

var selfValue = StartVars.Card.Back

var selected = false
var canSelect = true

export var isDiscard = false
export var isDrawnCard = false

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
	if isDrawnCard:
		return
	
	canSelect = can
	if canSelect:
		$Card/darken.hide()
	else:
		$Card/darken.show()

func setValue(val):
	selfValue = val
	$Card.texture_normal = load(StartVars.CardAsset(selfValue))

func selfName():
	return StartVars.CardName(selfValue)

func _ready():
	$Card.texture_normal = load(StartVars.CardAsset(selfValue))

func _on_Card_pressed():
	#print("hi")
	emit_signal("pressed_with_val", self)

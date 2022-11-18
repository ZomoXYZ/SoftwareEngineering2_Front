extends Node

#Checks if you are accessing a lobby via single or multiplayer
var singlePlayer = false

#This is a horrendous amount of hardcoding, yet alas, I do not care
var WanMos = [
	["Circle2", "Triangle2"],
	["Circle1", "Circle1", "Triangle2"],
	["Circle2", "Triangle1", "Triangle1"],
	["Circle1", "Circle1", "Triangle1", "Triangle1"],
	["CircleTriangle2", "CircleInverted2"], 
	["TriangleCircle2", "TriangleInverted2"],
	
]

enum Cards {
	Circle1 = 0
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

# CardAsset(Cards.Circle1)
func CardAsset(card):
	return "assets/sprites/cards/%s.png" % CardName(card)

# CardName(Cards.Circle1)
func CardName(card):
	return Cards.keys()[card]

# CardValue("Circle1")
func CardValue(name):
	return Cards.get(name)

# TODO convert to enum vals
var validHands = {
	"Circle1": [
		Cards.Circle1,
		Cards.CircleInverted1
	],
		
	"Circle2": [
		Cards.Circle2,
		Cards.CircleInverted2,
		Cards.Triangle2
	],
		
	"CircleInverted1": [
		Cards.CircleInverted1,
		Cards.Circle1
	],
		
	"CircleInverted2": [
		Cards.CircleInverted2,
		Cards.Circle2,
		Cards.CircleTriangle2
	],
		
	"CircleTriangle1": [
		Cards.CircleTriangle1,
		Cards.TriangleCircle1
	],
		
	"CircleTriangle2": [
		Cards.CircleTriangle2,
		Cards.TriangleCircle2,
		Cards.CircleInverted2
	],
		
	"Triangle1": [
		Cards.Triangle1,
		Cards.TriangleInverted1
	],
		
	"Triangle2": [
		Cards.Triangle2,
		Cards.TriangleInverted2,
		Cards.Circle2
	],
		
	"TriangleInverted1": [
		Cards.TriangleInverted1,
		Cards.Triangle1
	],
		
	"TriangleInverted2": [
		Cards.TriangleInverted2,
		Cards.Triangle2,
		Cards.TriangleCircle2
	],
		
	"TriangleCircle1": [
		Cards.CircleTriangle1,
		Cards.TriangleCircle1
	],
		
	"TriangleCircle2": [
		Cards.CircleTriangle2,
		Cards.TriangleCircle2,
		Cards.TriangleInverted2
	],
		
}

# returns a list of card types that can be played with the given cards
# returns null if the card list is empty
func getValidCards(cards):
	if cards.size() == 0:
		return null
	
	#Handling for the first card clicked
	elif cards.size() == 1:
		if CardName(cards[0]) == "Free":
			return Cards.values()
		elif CardName(cards[0]) == "CircleFree":
			return validHands["Circle1"] + validHands["Circle2"] + validHands["CircleInverted1"] + validHands["CircleInverted2"]
		elif CardName(cards[0]) == "TriangleFree":
			return validHands["Triangle1"] + validHands["Triangle2"] + validHands["TriangleInverted1"] + validHands["TriangleInverted2"]
		else:
			return validHands[CardName(cards[0])]
		
	#Handling for other cards
	else:
		


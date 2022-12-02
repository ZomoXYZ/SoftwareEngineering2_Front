extends Node

#Checks if you are accessing a lobby via single or multiplayer
var singlePlayer = false

func godot_sucks_join_array(array, delimiter = " "):
	var complete = ""
	
	for i in range(0,array.size()):
		if i != 0:
			complete += delimiter
		complete += array[i]
	
	return complete

func randomKey(dictionary, ignore = ""):
	while true:
		var rand = randi() % UserData.NameAdjectiveList.size()
		var key = dictionary.keys()[rand]
		if str(key) != str(ignore):
			return key

func randomIntKey(dictionary, ignore = ""):
	return int(randomKey(dictionary, ignore))

enum Cards {
	Circle1 = 0
	Circle2 #1
	CircleInverted1 #2
	CircleInverted2 #3

	CircleTriangle1 #4
	CircleTriangle2 #5

	Triangle1 #6
	Triangle2 #7
	TriangleInverted1 #8
	TriangleInverted2 #9

	TriangleCircle1 #10
	TriangleCircle2 #11

	Free #12
	CircleFree#13
	TriangleFree#14

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
		Cards.CircleInverted1,
		Cards.Free,
		Cards.CircleFree,
	],
		
	"Circle2": [
		Cards.Circle2,
		Cards.CircleInverted2,
		Cards.Triangle2,
		Cards.Free,
		Cards.CircleFree,
		Cards.TriangleFree,
	],
		
	"CircleInverted1": [
		Cards.CircleInverted1,
		Cards.Circle1,
		Cards.Free,
		Cards.CircleFree,
	],
		
	"CircleInverted2": [
		Cards.CircleInverted2,
		Cards.Circle2,
		Cards.CircleTriangle2,
		Cards.Free,
		Cards.CircleFree,
	],
		
	"CircleTriangle1": [
		Cards.CircleTriangle1,
		Cards.TriangleCircle1,
		Cards.Free,
	],
		
	"CircleTriangle2": [
		Cards.CircleTriangle2,
		Cards.TriangleCircle2,
		Cards.CircleInverted2,
		Cards.Free,
		Cards.CircleFree,
	],
		
	"Triangle1": [
		Cards.Triangle1,
		Cards.TriangleInverted1,
		Cards.Free,
		Cards.TriangleFree,
	],
		
	"Triangle2": [
		Cards.Triangle2,
		Cards.TriangleInverted2,
		Cards.Circle2,
		Cards.Free,
		Cards.CircleFree,
		Cards.TriangleFree,
	],
		
	"TriangleInverted1": [
		Cards.TriangleInverted1,
		Cards.Triangle1,
		Cards.Free,
		Cards.TriangleFree,
	],
		
	"TriangleInverted2": [
		Cards.TriangleInverted2,
		Cards.Triangle2,
		Cards.TriangleCircle2,
		Cards.Free,
		Cards.TriangleFree,
	],
		
	"TriangleCircle1": [
		Cards.CircleTriangle1,
		Cards.TriangleCircle1,
		Cards.Free,
	],
		
	"TriangleCircle2": [
		Cards.CircleTriangle2,
		Cards.TriangleCircle2,
		Cards.TriangleInverted2,
		Cards.Free,
		Cards.TriangleFree,
	],
		
}

#List of cards that can combine into different cards
#We set the basic combinations here and then define composite ones
#using unions of other combinations
var cardCombos = {
	"Triangle2": [
		["Triangle2"], 
		["Triangle1", "Triangle1"]
	],
	
	"Circle2": [
		["Circle2"], 
		["Circle1", "Circle1"]
	],
	
	"TriangleInverted2": [
		["TriangleInverted2"], 
		["TriangleInverted1", "TriangleInverted1"]
	],
	
	"CircleInverted2": [
		["CircleInverted2"],
		["CircleInverted1", "CircleInverted1"]
	],
	
	"CircleTriangle1": [
		["CircleTriangle1"],
		["Circle1", "Triangle1"]
	],
	
	"TriangleCircle1": [
		["TriangleCircle1"],
		["Circle1", "Triangle1"]
	],
}

func _ready():
	cardCombos["CircleTriangle2"] = [
		cardCombos["Triangle2"] + cardCombos["Circle2"],
		cardCombos["CircleTriangle1"] + cardCombos["CircleTriangle1"],
		["CircleTriangle2"]
	]
	cardCombos["TriangleCircle2"] = [
		cardCombos["Triangle2"] + cardCombos["Circle2"],
		cardCombos["TriangleCircle1"] + cardCombos["TriangleCircle1"],
		["TriangleCircle2"]
	]
	

func freeTypeCheck(free,card):
	if free.selfValue == Cards.TriangleFree:
		if card.selfValue == Cards.Triangle1 or card.selfValue == Cards.Triangle2 or card.selfValue == Cards.TriangleInverted1 or card.selfValue == Cards.TriangleInverted2:
			return true
		else:
			return false
	else:
		if card.selfValue == Cards.Circle1 or card.selfValue == Cards.Circle2 or card.selfValue == Cards.CircleInverted1 or card.selfValue == Cards.CircleInverted2:
			return true
		else:
			return false


func checkForFreePair(card1, card2):
	if card1.selfValue == Cards.CircleFree or card1.selfValue == Cards.TriangleFree:
		return freeTypeCheck(card1, card2)
	elif card2.selfValue == Cards.CircleFree or card2.selfValue == Cards.TriangleFree:
		return freeTypeCheck(card2, card1)
	elif card1.selfValue == Cards.Free:
		return true
	elif card2.selfValue == Cards.Free:
		return true
	else:
		return false

func custom_array_sort(a, b):
	if int(a) > int(b):
		return [int(b),int(a)]
	else:
		return [int(a),int(b)]

func array_fixer(array):
	var newArray = []
	for item in array:
		var counter = 0
		for i in range(array.size()):
			if i<array.size() and item == array[i]:
				counter +=1
		if counter> 2:
			newArray += [item]
	newArray +=[12,13,14]
	return newArray
# returns a list of card types that can be played with the given cards
# returns null if the card list is empty
func getValidCards(hand, cards):
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
	
	#Check for WAN MO
	elif cards.size() == 2:
		#cards = cards.sort()
		var x = custom_array_sort(cards[0],cards[1])
		var validArray = []
		
		if x == [1,7] or x == [9,11]  or x ==  [3,5]:
			print("help")
			for child in hand.get_children():
				print("got here")
				if !child.selected:
					for child2 in hand.get_children():
						if !child2.selected and child.selfValue == child2.selfValue:
							validArray += [child.selfValue,child2.selfValue]
						elif !child2.selected and checkForFreePair(child, child2):
							validArray +=  [child.selfValue,child2.selfValue]
			print(validArray)
			validArray = array_fixer(validArray)
			return validArray
		elif x == [12,12] or x == [12,13] or x == [12,14] or x == [13,13] or x == [13,14] or x == [14,14]:
			return [12,13,14]
		else:
			return []
			
	#Multiple cards selected
	else:
		print(cards)
		#sin^2 + cos^2 case
		if cards == [7, 1] or cards == [11, 9] or cards == [5, 3] or cards == [1,7] or cards == [9,11]  or cards ==  [3,5]:
			print("help")
			for child in hand.get_children():
				print("got here")
				if !child.selected:
					for child2 in hand.get_children():
						if !child2.selected and child.selfValue == child2.selfValue:
							validHands += [CardName(child),CardName(child2)]
						elif !child2.selected and checkForFreePair(child, child2):
							validHands += [CardName(child),CardName(child2)]
			return validHands
		elif cards == []:
			return validHands
		else:
			return []


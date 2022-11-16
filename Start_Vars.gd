extends Node

#Checks if you are accessing a lobby via single or multiplayer
var singlePlayer = false
var isHost = false

var validHands = {
	"Circle1":["Circle1", "CircleInverted1"],
	"Circle2":["Circle2","CircleInverted2","Triangle2"],
	"CircleInverted1":["CircleInverted1","Circle1"],
	"CircleInverted2":["CircleInverted2","Circle2","CircleTriangle2"],
	"CircleTriangle1":["CircleTriangle1","TriangleCircle1"],
	"CircleTriangle2":["CircleTriangle2","TriangleCircle2","CircleInverted2"],
	"Triangle1":["Triangle1","TriangleInverted1"],
	"Triangle2":["Triangle2","TriangleInverted2","Circle2"],
	"TriangleInverted1":["TriangleInverted1","Triangle1"],
	"TriangleInverted2":["TriangleInverted2","Triangle2","TriangleCircle2"],
	"TriangleCircle1":["CircleTriangle1","TriangleCircle1"],
	"TriangleCircle2":["CircleTriangle2","TriangleCircle2","TriangleInverted2"],
}


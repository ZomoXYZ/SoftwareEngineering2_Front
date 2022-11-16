extends Button

var code = ""
var id = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	self.text = "Lobby: %s" % code

func _on_LobbyButton_pressed():
	#Connects to the websocket
	print("Pressed LobbyButton")
	id.join(LobbyConn)

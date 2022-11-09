extends Button


var code = ""
var id = ""

#Creeper? Awww man
var client = WebSocketClient.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	self.text = "Lobby: %s" % code
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_closed")
	client.connect("connection_established", self, "_connected")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_LobbyButton_pressed():
	#Connects to the websocket
	var err = client.connect_to_url(Request.WS_URL)
	print(Request.WS_URL)
	print(err)
	if err != OK:
		print("Fat L")
	

func _connected(proto):
	print("Connected to websocket")
	client.get_peer(1).put_packet(("authorize %s %s" % [Request.token, OS.get_unique_id()]).to_utf8())
	
func _closed():
	print("Fat L")

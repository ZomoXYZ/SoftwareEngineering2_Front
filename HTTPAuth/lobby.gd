extends Node

var client = WebSocketClient.new()
var LobbyId = ""

signal disconnected()
signal joined_lobby()
signal game_start()

func _ready():
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_error")
	client.connect("connection_established", self, "_connected")
	client.connect("data_received", self, "_data")
	client.connect("server_close_request", self, "_server_close_request")

func _process(delta):
	client.poll()

func join(lobbyid):
	LobbyId = lobbyid
	var err = client.connect_to_url(Request.WS_URL)
	if err != OK:
		print("Error Connecting to %s, %s" % [Request.WS_URL, err])
		
func send(message):
	print("> %s" % message)
	client.get_peer(1).put_packet(message.to_utf8())

func _connected(_proto):
	print("Connected to websocket")
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	var command = "authorization %s %s" % [Request.token, OS.get_unique_id()];
	send(command)
	
func _closed(was_clean_close):
	if was_clean_close:
		print("Closed websocket cleanly")
	else:
		print("Closed websocket poorly")
	
func _error():
	print("Fat L")
	
func _data():
	var data = client.get_peer(1).get_packet().get_string_from_utf8()
	print("< %s" % data)
	
func _server_close_request(code, reason):
	print("Server requested close (Code %s): %s" % [code, reason])

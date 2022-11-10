extends Node

var client = WebSocketClient.new()
var Authorized = false

var ID = ""
var Code = ""
var Host = null
var Players = []

signal disconnected()
signal joined_lobby()
signal game_start()

func _ready():
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_error")
	client.connect("connection_established", self, "_connected")
	client.connect("data_received", self, "_data")
	client.connect("server_close_request", self, "_server_close_request")

func _process(_delta):
	client.poll()

func join(lobbyid):
	# set variables
	Authorized = false
	ID = lobbyid
	Code = ""
	Host = null
	Players = []
	# try connecting
	var err = client.connect_to_url(RequestEnv.WS_URL)
	if err != OK:
		print("Error Connecting to %s, %s" % [RequestEnv.WS_URL, err])
		ID = ""
		
func send(message):
	print("> %s" % message)
	client.get_peer(1).put_packet(message.to_utf8())
	
func receiveCommand():
	var message = client.get_peer(1).get_packet().get_string_from_utf8()
	print("< %s" % message)
	return Array(message.split(" "))

func _connected(_proto):
	print("Connected to websocket")
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	# we connected, time to authorize the session
	var command = "authorization %s %s" % [Request.token, OS.get_unique_id()];
	send(command)

func _data():
	var args = receiveCommand()
	var command = args.pop_front()
	# print("Command: %s, Args: %s" % [command, args])
	match(command):
		"authorized":
			command_authorized()
		"joined":
			command_joined(args)

func _closed(was_clean_close):
	if was_clean_close:
		print("Closed websocket cleanly")
	else:
		print("Closed websocket poorly")

func _error():
	print("Fat L")

func _server_close_request(code, reason):
	print("Server requested close (Code %s): %s" % [code, reason])

func command_authorized():
	# authorized session, can join the lobby now
	send("join %s" % ID)
	
func command_joined(args):
	# joined the lobby and received data about the lobby
	var data = JSON.parse(args[0]).result
	# set variables
	Authorized = true
	ID = data.id
	Code = data.code
	Host = data.host
	Players = data.players

	emit_signal("joined_lobby")

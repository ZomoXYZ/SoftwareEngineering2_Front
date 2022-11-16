extends Node

var client = WebSocketMultiplayerPeer.new()
var toPoll = false
var Authorized = false

var ID = ""
var Code = ""
var Host = null
var Players = []
var InLobby = true

var DiscardPile = -1
var Cards = []

func resetVariables():
	ID = ""
	Code = ""
	Host = null
	Players = []
	InLobby = true
	DiscardPile = -1
	Cards = []

signal disconnected()
signal joined_lobby()
signal game_starting()
signal players_updated()

func _ready():
	client.connect("connection_failed", Callable(self,"_on_connection_failed"))
	client.connect("connection_succeeded", Callable(self,"_on_connection_succeeded"))
	client.connect("server_disconnected", Callable(self,"_on_server_disconnected"))
	client.connect("peer_packet", Callable(self,"_on_peer_packet"))

func _process(delta):
	if toPoll:
		client.poll()

func join(lobbyid):
	# set variables
	Authorized = false
	resetVariables()
	ID = lobbyid

	# try connecting
	var err = client.create_client(RequestEnv.WS_URL)
	toPoll = true;
	if err != OK:
		print("Error Connecting to %s, %s" % [RequestEnv.WS_URL, err])
		ID = ""

func leave():
	client.disconnect_from_host()
	Authorized = false
	resetVariables()
	emit_signal("disconnected")

func send(message):
	print("> %s" % message)
	client.get_peer(0).put_packet(message.to_utf8_buffer())

func updateLobby(arg):
	# read json from string
	var test_json_conv = JSON.new()
	test_json_conv.parse(arg)
	var data = test_json_conv.result.get_data()

	# set variables
	Authorized = true
	ID = data.id
	Code = data.code
	Host = data.host
	Players = data.players

func _on_connection_succeeded():
	print("Connected to websocket")
	client.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	# we connected, time to authorize the session
	var command = "authorization %s %s" % [Request.token, OS.get_unique_id()];
	send(command)

func _on_connection_failed():
	print("Websocket Connection Failed")
	Authorized = false
	resetVariables()
	toPoll = false

func _on_server_disconnected():
	print("Websocket Connection Closed")
	Authorized = false
	resetVariables()
	toPoll = false

func _on_peer_packet(peerIndex):
	if peerIndex != 0:
		print("RECEIVING DATA from other peer? should always be 0 but is now ", peerIndex)
		return
	
	var message = client.get_peer(0).get_packet().get_string_from_utf8()
	print("< %s" % message)
	return Array(message.split(" "))

func _data(args):
	var command = args.pop_front()

	# print("Command: %s, Args: %s" % [command, args])

	match(command):
		# ping
		"ping":
			send("pong")

		# responses
		"authorized":
			command_authorized()
		"unauthorized":
			command_unauthorized()

		"joined":
			command_joined(args)
		"rejected":
			command_rejected()

		# lobby
		"playerupdate":
			command_lobby_playerupdate(args)

		"starting":
			command_lobby_starting(args)

		# errors
		"error":
			command_error_(args)

		"badcommand":
			command_error_badcommand(args)
		"badlobby":
			command_error_badlobby(args)
		
		"lobbyfull":
			command_error_lobbyfull()
		"lobbyinprogress":
			command_error_lobbyinprogress()

		_:
			print("Unknown command: %s" % command)

func _server_close_request(code, reason):
	print("Server requested close (Code %s): %s" % [code, reason])
	leave()

func command_authorized():
	# authorized session, can join the lobby now
	send("join %s" % ID)

func command_unauthorized():
	# bad authorization, abort
	print("Unauthorized session")
	
	Authorized = false
	resetVariables()

func command_joined(args):
	# joined the lobby and received data about the lobby
	updateLobby(args[0])
	emit_signal("joined_lobby")

func command_rejected():
	leave()

func command_lobby_playerupdate(args):
	# player updated (joined/left)
	updateLobby(args[0])
	emit_signal("players_updated")

func command_lobby_starting(args):
	# game starting
	InLobby = false
	var test_json_conv = JSON.new()
	test_json_conv.parse(args[0])
	var state = test_json_conv.result.get_data()
	DiscardPile = state.discardPile
	Cards = state.cards
	emit_signal("game_starting")

func command_error_(args):
	# generic error
	print("Generic error: %s" % " ".join(args))

func command_error_badcommand(args):
	# bad command
	print("Bad command: %s" % " ".join(args))

func command_error_badlobby(args):
	# bad lobby
	print("Bad lobby: %s" % " ".join(args))

func command_error_lobbyfull():
	# lobby full
	print("Lobby full")

func command_error_lobbyinprogress():
	# lobby in progress
	print("Lobby in progress")

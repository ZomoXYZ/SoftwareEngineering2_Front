extends Node

var client = WebSocketClient.new()
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
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_error")
	client.connect("connection_established", self, "_connected")
	client.connect("data_received", self, "_data")
	client.connect("server_close_request", self, "_server_close_request")

func _process(delta):
	if toPoll:
		client.poll()

func join(lobbyid):
	# set variables
	Authorized = false
	resetVariables()
	ID = lobbyid

	# try connecting
	var err = client.connect_to_url(RequestEnv.WS_URL)
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
	client.get_peer(1).put_packet(message.to_utf8())
	
func receive():
	var message = client.get_peer(1).get_packet().get_string_from_utf8()
	print("< %s" % message)
	return Array(message.split(" "))

func updateLobby(arg):
	# read json from string
	var data = JSON.parse(arg).result

	# set variables
	Authorized = true
	ID = data.id
	Code = data.code
	Host = data.host
	Players = data.players

func _connected(_proto):
	print("Connected to websocket")
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	# we connected, time to authorize the session
	var command = "authorization %s %s" % [Request.token, OS.get_unique_id()];
	send(command)

func _data():
	var args = receive()
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

func _closed(was_clean_close):
	if was_clean_close:
		print("Closed websocket cleanly")
	else:
		print("Closed websocket poorly")

	Authorized = false
	resetVariables()
	toPoll = false

func _error():
	print("Fat L")

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
	var state = JSON.parse(args[0]).result
	DiscardPile = state.discardPile
	Cards = state.cards
	emit_signal("game_starting")

func command_error_(args):
	# generic error
	print("Generic error: %s" % args.join(" "))

func command_error_badcommand(args):
	# bad command
	print("Bad command: %s" % args.join(" "))

func command_error_badlobby(args):
	# bad lobby
	print("Bad lobby: %s" % args.join(" "))

func command_error_lobbyfull():
	# lobby full
	print("Lobby full")

func command_error_lobbyinprogress():
	# lobby in progress
	print("Lobby in progress")

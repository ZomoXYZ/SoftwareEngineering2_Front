extends Node

var client = WebSocketClient.new()
var toPoll = false
var Authorized = false

var ID = ""
var LOBBY_PASSWORD = ""
var Code = ""
var Host = ""
var Players = []
var InLobby = true

var DiscardPile = -1
var Cards = []

var Points = []
var Turn = ""

enum DrawFrom {
	DECK = 0,
	DISCARD
}

enum HandTypes {
	SINGLEFREE = 0,
	PAIR,
	PAIR_INVERTED,
	DOUBLE_FREE,
	TRIPLE_FREE,
	DOUBLE_SHAPE_PAIR,
	BIG_PAIR,
	QUAD_FREE,
	WANMO_DOUBLE_SHAPE_PAIR,
	WANMO_BIG_PAIR,
	PASS,
}

func isMyTurn():
	return Turn == UserData.ID

func isHost():
	return Host == UserData.ID

func getTurnIndex():
	for i in range(Players.size()):
		if Players[i].id == LobbyConn.Turn:
			return i

func resetVariables():
	ID = ""
	Code = ""
	Host = null
	Players = []
	InLobby = true
	DiscardPile = -1
	Cards = []

# general
signal disconnected()

# before lobby
signal joined_lobby()

# in lobby
signal game_starting()
signal players_updated()

# in game
signal player_turn(player)
signal card_drew(from, card) # from: DrawFrom.DRAW_FROM_DECK or DrawFrom.DRAW_FROM_DISCARD
signal card_discarded(card)
signal cards_played(handType, cards, wanmoPair) # cards and wanmoPair will be null if passed
signal turn_ended(cards) # cards automatically drawn

signal game_over(playerID) # playerID winner

func _ready():
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_error")
	client.connect("connection_established", self, "_connected")
	client.connect("data_received", self, "_data")
	client.connect("server_close_request", self, "_server_close_request")

func _process(_delta):
	if toPoll:
		client.poll()

func join(lobbyid, password = ""):
	# set variables
	Authorized = false
	resetVariables()
	ID = lobbyid
	LOBBY_PASSWORD = password

	# try connecting
	var err = client.connect_to_url(RequestEnv.WS_URL)
	toPoll = true;
	if err != OK:
		print("Error Connecting to %s, %s" % [RequestEnv.WS_URL, err])
		ID = ""

func join_game():
	send("ingame")

func leave():
	client.disconnect_from_host()
	Authorized = false
	toPoll = false
	resetVariables()
	emit_signal("disconnected")
		
func draw(from):
	send("draw %s" % from)
		
func discard(card):
	send("discard %s" % card)
		
func startGame():
	if isHost():
		send("start")
		
func setPassword(password):
	if isHost():
		send("setpassword %s" % password)
		
func clearPassword():
	if isHost():
		send("setpassword")
		
func setPointGoal(goal):
	if isHost():
		send("setpointgoal %s" % goal)
		
func kickPlayer(playerID):
	if isHost():
		send("kick %s" % playerID)
		
func play(cards, wanmoPair):
	if cards == null:
		send("play")
	else:
		var cardsJson = {
			"cards": cards
		}
		if wanmoPair != null:
			cardsJson["wanmo"] = wanmoPair
		send("play %s" % JSON.print(cardsJson))


func send(message):
	print("> %s" % message)
	client.get_peer(1).put_packet(message.to_utf8())
	
func receive():
	var message = client.get_peer(1).get_packet().get_string_from_utf8()
	print("< %s" % message)
	return Array(message.split(" "))

func removeCard(card):
	for i in range(Cards.size()):
		if Cards[i] == card:
			Cards.remove(i)
			break

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

		# game
		"turn":
			command_game_turn(args)
		"drew":
			command_game_drew(args)
		"discarded":
			command_game_discarded(args)
		"played":
			command_game_played(args)
		"passed":
			command_game_passed()
		"autodraw":
			command_game_autodraw(args)
		"gameover":
			command_game_gameover(args)

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

	leave()

func _error():
	print("Fat L")

func _server_close_request(code, reason):
	print("Server requested close (Code %s): %s" % [code, reason])
	leave()

func command_authorized():
	# authorized session, can join the lobby now
	if LOBBY_PASSWORD != "":
		send("join %s %s" % [ID, LOBBY_PASSWORD])
	else:
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

func command_game_turn(args):
	var state = JSON.parse(args[0]).result
	Cards = state.cards
	DiscardPile = state.discardPile
	Points = state.points
	Turn = state.turn
	emit_signal("player_turn", state.turn)

func command_game_drew(args):
	var drew = JSON.parse(args[0]).result
	if isMyTurn():
		Cards.append(drew.card)
		emit_signal("card_drew", drew.from, drew.card)
	else:
		emit_signal("card_drew", drew.from, null)

func command_game_discarded(args):
	var card = int(args[0])
	if isMyTurn():
		removeCard(card)
	DiscardPile = card
	emit_signal("card_discarded", card)

func command_game_played(args):
	var data = JSON.parse(args[0]).result
	var cards = data.cards
	var type = data.type
	var wanmo = data.wanmo
	if isMyTurn():
		for card in cards:
			removeCard(card)
	emit_signal("cards_played", type, cards, wanmo)

func command_game_passed():
	emit_signal("cards_played", HandTypes.PASS, null, null)

func command_game_autodraw(args):
	var cards = JSON.parse(args[0]).result.cards
	Cards = Cards + cards
	emit_signal("turn_ended", cards)

func command_game_gameover(args):
	var playerid = args[0]
	emit_signal("game_over", playerid)


func command_error_(args):
	# generic error
	print("Generic error: %s" % StartVars.godot_sucks_join_array(args))

func command_error_badcommand(args):
	# bad command
	print("Bad command: %s" % StartVars.godot_sucks_join_array(args))

func command_error_badlobby(args):
	# bad lobby
	print("Bad lobby: %s" % StartVars.godot_sucks_join_array(args))

func command_error_lobbyfull():
	# lobby full
	print("Lobby full")

func command_error_lobbyinprogress():
	# lobby in progress
	print("Lobby in progress")

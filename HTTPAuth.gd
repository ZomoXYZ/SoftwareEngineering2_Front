extends Node

const Schema = "http"
const Host = "localhost"
const Port = 8080
const Path = ""

var token = ""

var client = null

var ready = false

var PlayerNameAdjective = -1
var PlayerNameNoun = -1
var PlayerPicture = -1

func _init():
	client = HTTPClient.new()
	var err = client.connect_to_host(Host, Port)
	if err != OK:
		print("Offline")
		return

	# Wait until resolved and connected.
	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		print("Connecting...")
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			yield(Engine.get_main_loop(), "idle_frame")

	if client.get_status() == HTTPClient.STATUS_CANT_CONNECT:
		print("Offline")
		return
		
	assert(client.get_status() == HTTPClient.STATUS_CONNECTED) # Check if the connection was made successfully.
	ready = true
	
	var jsonResult = request("/authorization", HTTPClient.METHOD_GET, null, true)
	assert(jsonResult.error == OK)
	token = jsonResult.result.token
	
	var playerData = getUserData()
	if playerData == null:
		var selfData = request("/self")
		assert(selfData.error == OK)
		setUserData(selfData.result)
		playerData = selfData.result
		print("retrieved user data from server")
	else:
		request("/self", HTTPClient.METHOD_POST, playerData)
		print("sent user data to server")
	
	print("Name: %s %s, Picture: %s" % [playerData.name.adjective, playerData.name.noun, playerData.picture])
	
	PlayerNameAdjective = playerData.name.adjective
	PlayerNameNoun = playerData.name.noun
	PlayerPicture = playerData.picture

func request(path, method = HTTPClient.METHOD_GET, body = null, noToken = false):
	assert(ready && (noToken || token != ""))
	# Some headers
	var headers = [ "UUID: %s" % OS.get_unique_id() ]
	if !noToken:
		headers.append("Authorization: %s" % token)
		
	var bodyStr = ""
	if body != null:
		bodyStr = JSON.print(body)

	var err = client.request(method, path, headers, bodyStr)
	assert(err == OK)

	# wait for request to complete
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		print("Requesting...")
		if OS.has_feature("web"):
			yield(Engine.get_main_loop(), "idle_frame")
		else:
			OS.delay_msec(500)

	assert(client.get_status() == HTTPClient.STATUS_BODY or client.get_status() == HTTPClient.STATUS_CONNECTED)

	if client.has_response():
		headers = client.get_response_headers_as_dictionary() 
		print("code: ", client.get_response_code())
		print("**headers:\\n", headers)

		# buffer
		var rb = PoolByteArray()

		# fill buffer with chunks
		while client.get_status() == HTTPClient.STATUS_BODY:
			client.poll()
			var chunk = client.read_response_body_chunk()
			if chunk.size() == 0:
				if not OS.has_feature("web"):
					OS.delay_usec(1000)
				else:
					yield(Engine.get_main_loop(), "idle_frame")
			else:
				rb = rb + chunk

		print("bytes got: ", rb.size())
		var text = rb.get_string_from_ascii()
		print("Text: ", text)
		return JSON.parse(text)
		
	return null

func getUserData():
	var file = File.new()
	file.open("user://save_game.dat", File.READ)
	var content = file.get_as_text()
	file.close()
	var jsonResult = JSON.parse(content)
	if jsonResult.error != OK || !jsonResult.result.has('name') || !jsonResult.result.name.has('adjective') || !jsonResult.result.name.has('noun') || !jsonResult.result.has('picture'):
		return null
	return jsonResult.result
	

func setUserData(data):
	assert(data.has('name') && data.name.has('adjective') && data.name.has('noun') && data.has('picture'))
	var name = data.name
	var picture = data.picture
	var content = JSON.print({
		"name": name,
		"picture": picture
	})
	var file = File.new()
	file.open("user://save_game.dat", File.WRITE)
	file.store_string(content)
	file.close()

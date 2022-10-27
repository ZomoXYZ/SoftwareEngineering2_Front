extends Node

const Schema = "http"
const Host = "localhost"
const Port = 8080
const Path = ""
const BASE_URL = "%s://%s:%s%s" % [Schema, Host, Port, Path]

var token = ""
var lastChecked = -1

var PlayerNameAdjective = -1
var PlayerNameNoun = -1
var PlayerPicture = -1
	
# createRequest(self, "_on_request_complete")
func createRequest(root, callback, endpoint, method = HTTPClient.METHOD_GET, body = null, noToken = false):
	assert(noToken || token != "")

	# create request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", root, callback)

	# Some headers
	var headers = [ "UUID: %s" % OS.get_unique_id() ]
	if !noToken:
		headers.append("Authorization: %s" % token)
		
	var bodyStr = ""
	if body != null:
		bodyStr = JSON.print(body)
	
	var error = http_request.request(BASE_URL + endpoint, headers, Schema.to_lower() == "https", method, bodyStr)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func getUserData():
	var file = File.new()
	file.open("user://userdata.dat", File.READ)
	var content = file.get_as_text()
	file.close()
	var jsonResult = JSON.parse(content)
	if jsonResult.error != OK || !jsonResult.result.has('name') || !jsonResult.result.name.has('adjective') || !jsonResult.result.name.has('noun') || !jsonResult.result.has('picture'):
		return null
	return jsonResult.result
	
func authorizeSession(force = false):
	# only run every 15 seconds at most
	# TODO make this an hour if they have a token
	if force || (lastChecked != -1 && lastChecked > Time.get_ticks_msec() - 15 * 1000):
		print("Checking too quick")
		return
	
	lastChecked = Time.get_ticks_msec()
	
	if token != "":
		print("TODO confirm token")
		return
	
	createRequest(self, "_on_get_token", "/authorization", HTTPClient.METHOD_GET, null, true)
	

func setUserData(data):
	assert(data.has('name') && data.name.has('adjective') && data.name.has('noun') && data.has('picture'))
	var name = data.name
	var picture = data.picture
	var content = JSON.print({
		"name": name,
		"picture": picture
	})
	var file = File.new()
	file.open("user://userdata.dat", File.WRITE)
	file.store_string(content)
	file.close()

func _on_get_token(result, response_code, headers, body):
	# TODO check result/response_code/etc

	var jsonResult = JSON.parse(body.get_string_from_utf8())
	print(body.get_string_from_utf8())
	if jsonResult.error != OK || !jsonResult.result.has("token"):
		print("Error loading token from Server's JSON")
		return
		
	token = jsonResult.result.token
	print("Got token: %s" % token)
	
	var playerData = getUserData()
	if playerData == null:
		createRequest(self, "_on_get_userdata", "/self")
	else:
		createRequest(self, "_on_get_userdata", "/self", HTTPClient.METHOD_POST, playerData)

func _on_get_userdata(result, response_code, headers, body):
	var jsonResult = JSON.parse(body.get_string_from_utf8())
	if jsonResult.error != OK:
		print("Error loading userdata from Server's JSON")
		return
	var playerData = jsonResult.result
	setUserData(playerData)
	print("Name: %s %s, Picture: %s" % [playerData.name.adjective, playerData.name.noun, playerData.picture])
	
	PlayerNameAdjective = playerData.name.adjective
	PlayerNameNoun = playerData.name.noun
	PlayerPicture = playerData.picture

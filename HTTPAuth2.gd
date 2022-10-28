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
	http_request.set_timeout(1) # TODO change timeout time
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


# func verifyResult(result):
# 	if result == HTTPRequest.RESULT_SUCCESS:
# 		return Status.Online
# 	if result in [
# 			HTTPRequest.RESULT_CANT_CONNECT,
# 			HTTPRequest.RESULT_CANT_RESOLVE,
# 			HTTPRequest.RESULT_NO_RESPONSE,
# 			HTTPRequest.RESULT_REQUEST_FAILED,
# 			HTTPRequest.RESULT_TIMEOUT,
# 		]:
# 		print("OFFLINE")
# 		return Status.Offline
# 	# if result in [
# 	# 		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH,
# 	# 		HTTPRequest.RESULT_CONNECTION_ERROR,
# 	# 		HTTPRequest.RESULT_SSL_HANDSHAKE_ERROR,
# 	# 		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED,
# 	# 		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN,
# 	# 		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED,
# 	# 	]:
# 	# 	print("OFFLINE/ERROR %s" % result)
# 	# 	return Status.Error
# 	return Status.Error

enum Status {Online, Offline, Error}

# returns: [status, body]
func parseResponse(result, response_code, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("OFFLINE")
		return [Status.Offline, null]
	print("ONLINE")

	if response_code == 401:
		print("Request Error")
		return [Status.Error, null]
	if response_code == 401:
		print("Unauthorized")
		return [Status.Error, null]
	if response_code == 404:
		print("Missing")
		return [Status.Error, null]
	if response_code != 200:
		print("Unknown Response Code %s" % response_code)
		return [Status.Error, null]

	var bodyString = body.get_string_from_utf8()
	
	if bodyString == "":
		return [Status.Online, null]
	
	var jsonResult = JSON.parse(bodyString)
	print(bodyString)

	if jsonResult.error != OK:
		print("Error loading token from Server's JSON: %s" % jsonResult.error)
		return [Status.Error, null]

	return [Status.Online, jsonResult.result]

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

func _on_get_token(result, response_code, _headers, bodyString):
	var response = parseResponse(result, response_code, bodyString)
	if response[0] != Status.Online || response[1] == null:
		return
		
	token = response[1].token
	print("Got token: %s" % token)
	
	var playerData = getUserData()
	if playerData == null:
		createRequest(self, "_on_get_userdata", "/self")
	else:
		createRequest(self, "_on_get_userdata", "/self", HTTPClient.METHOD_POST, playerData)

func _on_get_userdata(result, response_code, _headers, bodyString):
	var response = parseResponse(result, response_code, bodyString)
	if response[0] != Status.Online || response[1] == null:
		return
	
	var playerData = response[1]
	setUserData(playerData)
	print("Name: %s %s, Picture: %s" % [playerData.name.adjective, playerData.name.noun, playerData.picture])
	
	PlayerNameAdjective = playerData.name.adjective
	PlayerNameNoun = playerData.name.noun
	PlayerPicture = playerData.picture

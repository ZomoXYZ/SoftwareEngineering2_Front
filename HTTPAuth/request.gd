extends Node

var token = ""
var lastChecked = -1
var online = false

signal user_online()
signal user_offline()

enum Status {Online, Offline, Error}

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
		
	# convert body
	var bodyStr = ""
	if body != null:
		bodyStr = JSON.print(body)
	
	# print request
	var headersPrintString = ""
	for h in headers:
		headersPrintString += "\n\t" + h 
	var bodyPrintString = ""
	if bodyStr != "":
		bodyPrintString = "\n\t" + bodyStr
	
	print("Requesting %s%s%s%s" % [RequestEnv.BASE_URL, endpoint, headersPrintString, bodyPrintString])
	
	# get errors
	var error = http_request.request(RequestEnv.BASE_URL + endpoint, headers, RequestEnv.Schema_http.to_lower() == "https", method, bodyStr)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

# returns: [status, body]
func parseResponse(result, response_code, body):
	# check result for errors
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Request Offline")
		return [Status.Offline, null]
	
	# check response codes
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

	# convert body
	var bodyString = body.get_string_from_utf8()
	if bodyString == "":
		return [Status.Online, null]
	
	var jsonResult = JSON.parse(bodyString)
	#print("Response Raw Body: %s" % bodyString)
	
	if jsonResult.error != OK:
		print("Error loading token from Server's JSON: %s\n\nRaw Body:\n%s" % [jsonResult.error, bodyString])
		return [Status.Error, null]

	# return Json body
	return [Status.Online, jsonResult.result]

func authorizeSession(force = false):
	# only run every 15 seconds at most
	# TODO make this an hour if they have a token
	if force || (lastChecked != -1 && lastChecked > Time.get_ticks_msec() - 15 * 1000):
		print("Checking too quick")
		if token != "" && UserData.PlayerNameAdjective != -1 && UserData.PlayerNameNoun != -1 && UserData.PlayerPicture != -1:
			print("known online")
			set_online()
			return
		else:
			print("known offline")
			set_offline()
		return
	
	lastChecked = Time.get_ticks_msec()
	
	if token != "":
		var body = {
			"token": token
		}
		createRequest(self, "_on_get_token", "/authorization", HTTPClient.METHOD_POST, body, true)
		return
	
	createRequest(self, "_on_get_token", "/authorization", HTTPClient.METHOD_GET, null, true)

func _on_get_token(result, response_code, _headers, bodyString):
	var response = parseResponse(result, response_code, bodyString)
	if response[0] != Status.Online || response[1] == null:
		set_offline()
		return
		
	token = response[1].token
	print("Got token: %s" % token)
	
	var playerData = UserData.getUserData()
	if playerData == null:
		createRequest(self, "_on_get_userdata", "/self")
	else:
		createRequest(self, "_on_get_userdata", "/self", HTTPClient.METHOD_POST, playerData)

func _on_get_userdata(result, response_code, _headers, bodyString):
	var response = parseResponse(result, response_code, bodyString)
	if response[0] != Status.Online || response[1] == null:
		set_offline()
		return
	
	var playerData = response[1]
	UserData.setUserData(playerData)
	set_online()

func set_online():
	online = true
	emit_signal("user_online")

func set_offline():
	online = false
	emit_signal("user_offline")

extends Node

const Schema = "http"
const Host = "localhost"
const Port = 8080
const Path = ""

var token = ""
var lastChecked = -1

var PlayerNameAdjective = -1
var PlayerNameNoun = -1
var PlayerPicture = -1

func requestNoToken(endpoint, method = HTTPClient.METHOD_GET, body = null, headers = []):
	headers.append("UUID: %s" % OS.get_unique_id())
	var request = HTTPAuthClass.request(endpoint, method, body, headers, 1)
	if request == HTTPAuthClass.Status.Offline:
		print("OFFLINE")
		return null
	return request

func request(endpoint, method = HTTPClient.METHOD_GET, body = null, headers = []):
	assert(token != "")
	headers.append("Authorization: %s" % token)
	return requestNoToken(endpoint, method, body, headers)

func getUserData():
	var file = File.new()
	file.open("user://userdata.dat", File.READ)
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
	file.open("user://userdata.dat", File.WRITE)
	file.store_string(content)
	file.close()
	
func authorizeSession(force = false):
	# only run every 15 seconds at most
	if force || (lastChecked != -1 && lastChecked > Time.get_ticks_msec() - 15 * 1000):
		print("Checking too quick")
		return
	
	lastChecked = Time.get_ticks_msec()
	
	if token != "":
		print("TODO confirm token")
		return
	
	var jsonResult = requestNoToken("/authorization")
	if jsonResult == null:
		return
	
	assert(jsonResult.error == OK && !jsonResult.result.has("error"))
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

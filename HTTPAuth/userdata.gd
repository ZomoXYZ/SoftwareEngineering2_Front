extends Node

var ID = ""
var PlayerNameAdjective = -1
var PlayerNameNoun = -1
var PlayerPicture = -1

var NameAdjectiveList = null
var NameNounList = null
# PictureList is just an array of keys
var PictureList = null

var GotMeta = false

signal user_updated()
signal got_meta()

func asObj():
	return objFrom(PlayerNameAdjective, PlayerNameNoun, PlayerPicture)

func objFrom(adjective, noun, picture):
	var obj = {}
	obj["name"] = {}
	obj.name["adjective"] = adjective
	obj.name["noun"] = noun
	obj["picture"] = picture
	return obj

func loadUserData():
	var file = File.new()
	file.open("user://userdata.dat", File.READ)
	var content = file.get_as_text()
	file.close()
	var jsonResult = JSON.parse(content)
	if jsonResult.error != OK || !jsonResult.result.has('name') || !jsonResult.result.name.has('adjective') || !jsonResult.result.name.has('noun') || !jsonResult.result.has('picture'):
		return null
	
	PlayerNameAdjective = int(jsonResult.result.name.adjective)
	PlayerNameNoun = int(jsonResult.result.name.noun)
	PlayerPicture = int(jsonResult.result.picture)
	
	return jsonResult.result

# doesnt send to server
func setUserData(data):
	assert(data.has('name') && data.name.has('adjective') && data.name.has('noun') && data.has('picture'))
	
	PlayerNameAdjective = int(data.name.adjective)
	PlayerNameNoun = int(data.name.noun)
	PlayerPicture = int(data.picture)

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
	
	emit_signal("user_updated")

# sends to server
func updateUserData(data):
	assert(data.has('name') && data.name.has('adjective') && data.name.has('noun') && data.has('picture'))
	Request.createRequest(self, "_on_update_userdata", "/self", HTTPClient.METHOD_POST, data)
	
func _on_update_userdata(result, response_code, _headers, bodyString):
	var response = Request.parseResponse(result, response_code, bodyString)
	if response[0] != Request.Status.Online:
		return
	
	setUserData(response[1])

func setUserAdj(adj):
	updateUserData({
		"name": {
			"adjective": int(adj),
			"noun": PlayerNameNoun
		},
		"picture": PlayerPicture
	})

func setUserNoun(noun):
	updateUserData({
		"name": {
			"adjective": PlayerNameAdjective,
			"noun": int(noun)
		},
		"picture": PlayerPicture
	})

func setUserPic(pic):
	updateUserData({
		"name": {
			"adjective": PlayerNameAdjective,
			"noun": PlayerNameNoun
		},
		"picture": int(pic)
	})


func retrieveMetaData():
	if NameAdjectiveList != null && NameNounList != null && PictureList != null:
		GotMeta = true
		emit_signal("got_meta")

	Request.createRequest(self, "_on_meta_names", "/meta/names")

func _on_meta_names(result, response_code, _headers, bodyString):
	var response = Request.parseResponse(result, response_code, bodyString)
	if response[0] != Request.Status.Online || response[1] == null:
		return
	var data = response[1]
	NameAdjectiveList = data.adjectives
	NameNounList = data.nouns

	Request.createRequest(self, "_on_meta_pictures", "/meta/pictures")

func _on_meta_pictures(result, response_code, _headers, bodyString):
	var response = Request.parseResponse(result, response_code, bodyString)
	if response[0] != Request.Status.Online || response[1] == null:
		return
	var data = response[1]
	PictureList = data.avatars

	print("got the lists")
	print(NameAdjectiveList)
	print(NameNounList)
	print(PictureList)
	
	GotMeta = true
	emit_signal("got_meta")

func getAdjective(num):
	if NameAdjectiveList == null || !NameAdjectiveList.has(str(num)):
		return ""
	return NameAdjectiveList[str(num)]

func getNoun(num):
	if NameNounList == null || !NameNounList.has(str(num)):
		return ""
	return NameNounList[str(num)]

func getPicture(num):
	if PictureList == null || !(num in PictureList):
		return ""
	return "/meta/picture/%s" % num

func getMyAdjective():
	return getAdjective(PlayerNameAdjective)

func getMyNoun():
	return getNoun(PlayerNameNoun)

func getMyPicture():
	return getPicture(PlayerPicture)

extends Node

var PlayerNameAdjective = -1
var PlayerNameNoun = -1
var PlayerPicture = -1

func getUserData():
	var file = FileAccess.open("user://userdata.dat", FileAccess.READ)
	var contentString = file.get_as_text()
	var contentJson = JSON.parse_string(contentString)
	if contentJson == null || !contentJson.has('name') || !contentJson.name.has('adjective') || !contentJson.name.has('noun') || !contentJson.has('picture'):
		return null
	
	PlayerNameAdjective = contentJson.name.adjective
	PlayerNameNoun = contentJson.name.noun
	PlayerPicture = contentJson.picture

	return contentJson


func setUserData(data):
	assert(data.has('name') && data.name.has('adjective') && data.name.has('noun') && data.has('picture'))
	
	PlayerNameAdjective = data.name.adjective
	PlayerNameNoun = data.name.noun
	PlayerPicture = data.picture

	var name = data.name
	var picture = data.picture
	var content = JSON.stringify({
		"name": name,
		"picture": picture
	})
	var file = FileAccess.open("user://userdata.dat", FileAccess.WRITE)
	file.store_string(content)

func setUserAdj(adj):
	setUserData({
		"name": {
			"adjective": adj,
			"noun": PlayerNameNoun
		},
		"picture": PlayerPicture
	})

func setUserNoun(noun):
	setUserData({
		"name": {
			"adjective": PlayerNameAdjective,
			"noun": noun
		},
		"picture": PlayerPicture
	})

func setUserPic(pic):
	setUserData({
		"name": {
			"adjective": PlayerNameAdjective,
			"noun": PlayerNameNoun
		},
		"picture": pic
	})

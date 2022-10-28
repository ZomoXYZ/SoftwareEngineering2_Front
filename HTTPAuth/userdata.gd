extends Node

var PlayerNameAdjective = -1
var PlayerNameNoun = -1
var PlayerPicture = -1

func getUserData():
	var file = File.new()
	file.open("user://userdata.dat", File.READ)
	var content = file.get_as_text()
	file.close()
	var jsonResult = JSON.parse(content)
	if jsonResult.error != OK || !jsonResult.result.has('name') || !jsonResult.result.name.has('adjective') || !jsonResult.result.name.has('noun') || !jsonResult.result.has('picture'):
		return null
	
	PlayerNameAdjective = jsonResult.result.name.adjective
	PlayerNameNoun = jsonResult.result.name.noun
	PlayerPicture = jsonResult.result.picture

	return jsonResult.result


func setUserData(data):
	assert(data.has('name') && data.name.has('adjective') && data.name.has('noun') && data.has('picture'))
	
	PlayerNameAdjective = data.name.adjective
	PlayerNameNoun = data.name.noun
	PlayerPicture = data.picture

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

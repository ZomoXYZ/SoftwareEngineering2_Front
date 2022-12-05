extends Control


# Declare member variables here. Examples:
var key
signal pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func key_setter(newKey):
	key = newKey
	Request.createRequest(self, "_http_request_completed2", UserData.getPicture(key))
	
func set_texture(texture):
	$TextureButton.texture_normal = texture

func size_setter(vector):
	$TextureButton.set_size(vector)

func _http_request_completed2(result, response_code, headers, body):
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	if image_error != OK:
		print(image_error)
		print("An error occurred while trying to display the image.")
		return
	
	yield(get_tree(), "idle_frame")
	var texture = ImageTexture.new()
	texture.create_from_image(image, 4)
	set_texture(texture)


func _on_TextureButton_pressed():
	emit_signal("pressed",key)

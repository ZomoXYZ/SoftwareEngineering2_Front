extends Node

const Schema = "http"
const Host = "localhost"
const Port = 8080
const Path = ""
const BASE_URL = "%s://%s:%s%s" % [Schema, Host, Port, Path]

enum Status {Online, Offline}

signal request_ready(status, body)

# timeout is in seconds
func request(endpoint, method = HTTPClient.METHOD_GET, body = null, headers = null, timeout = 1):
	var client = HTTPClient.new()
	var err = client.connect_to_host(Host, Port)
	if err != OK:
		print("Offline")
		emit_signal("request_ready", Status.Offline)
		return Status.Offline

	var timer = 0
	while (client.get_status() == HTTPClient.STATUS_CONNECTING || client.get_status() == HTTPClient.STATUS_RESOLVING) && timer < timeout * 10:
		client.poll()
		print("Connecting...")
		timer+=1
		if not OS.has_feature("web"):
			OS.delay_msec(100)
		else:
			yield(Engine.get_main_loop(), "idle_frame")

	if timer >= timeout * 10:
		emit_signal("request_ready", Status.Offline)
		return Status.Offline
	
	var bodyStr = ""
	if body != null:
		bodyStr = JSON.print(body)

	err = client.request(method, BASE_URL + endpoint, headers, bodyStr)
	if err != OK:
		emit_signal("request_ready", Status.Offline)
		return Status.Offline

	while client.get_status() == HTTPClient.STATUS_REQUESTING && timer < timeout * 10:
		client.poll()
		print("Requesting...")
		timer+=1
		if OS.has_feature("web"):
			yield(Engine.get_main_loop(), "idle_frame")
		else:
			OS.delay_msec(500)

	if timer >= timeout * 10:
		emit_signal("request_ready", Status.Offline)
		return Status.Offline

	if client.get_status() != HTTPClient.STATUS_BODY && client.get_status() != HTTPClient.STATUS_CONNECTED:
		emit_signal("request_ready", Status.Offline)
		return Status.Offline

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
					OS.delay_usec(100)
				else:
					yield(Engine.get_main_loop(), "idle_frame")
			else:
				rb = rb + chunk

		print("bytes got: ", rb.size())
		var text = rb.get_string_from_ascii()
		print("Text: ", text)
		emit_signal("request_ready", Status.Online, JSON.parse(text))
		return JSON.parse(text)
		
	emit_signal("request_ready", Status.Online, null)
	return null

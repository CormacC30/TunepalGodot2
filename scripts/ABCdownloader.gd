extends Node

class_name ABCDownloader

# Base URL for thesession.org API
var session_url =  "https://raw.githubusercontent.com/adactio/TheSession-data/refs/heads/main/json/tunes.json"
# HTTP request object
var http_request : HTTPRequest
#var http_request = HTTPRequest.new()

# Signals
signal download_progress(current_id, successful_count, total_attempted)
signal download_completed(total_downloaded)
signal download_error(id, error_message)

func _ready():
	# Create the HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.use_threads = true
	# Connect the signal here
	http_request.request_completed.connect(_on_request_completed)
	# http_request.request_completed.connect(_on_request_completed)

# Start downloading all tunes
func start_download():
	if http_request == null:
		http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.use_threads = true
		http_request.request_completed.connect(_on_request_completed)
	# http_request.timeout = 10.0
	var headers = ["User-Agent: Godot"]

	var error = http_request.request(session_url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("Failed to start HTTP request: ", error)
		# print("Error details: ", error_string(error))
		# download_error.emit(0, "Failed to start request: " + error_string(error))
		return
	print("Downloading from: ", session_url)

func _on_request_completed(result, response_code, headers, body):
	var current_id = 0 
	var save_path = ProjectSettings.globalize_path("user://session_tunes.json")
	if result != HTTPRequest.RESULT_SUCCESS:
		printerr("Request failed: ", result)
		return

	if response_code != 200:
		printerr("Request failed with response code: ", response_code)
		return
	
	print("Download completed successfully!")

	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if not save_file:
		printerr("Failed to open file for writing: ", FileAccess.get_open_error())
		return

	save_file.store_buffer(body) # stores the request body to your file
	save_file.close()

	print("JSON file saved to: ", save_path)

	var parser = JSONParser.new()
	parser.parse_json_file(save_path) # call the parser
	download_completed.emit(1)


# func error_string(code):
# 	match code:
# 		ERR_CANT_CONNECT: return "Cannot connect to host"
# 		ERR_CANT_OPEN: return "Cannot open connection"
# 		ERR_CANT_RESOLVE: return "Cannot resolve hostname"
# 		ERR_CONNECTION_ERROR: return "Connection error"
# 		ERR_SSL_HANDSHAKE_ERROR: return "SSL handshake error"
# 		ERR_SSL_CERTIFICATE_ERROR: return "SSL certificate error"
# 		_: return "Error code: " + str(code)

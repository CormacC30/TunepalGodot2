extends Control
class_name DownloadButton

@onready var import_button = $import_button
@onready var download_button = $DownloadButton
@onready var progress_bar = $progress_bar
@onready var status_label = $status_label
@onready var file_dialog = $file_dialog
# @onready var json_parser = $JsonParser

var json_parser = JSONParser.new()

func _ready():
	download_button.pressed.connect(_on_download_button_pressed)
	#add_child(json_parser)
	json_parser.connect("import_progress", _on_download_progress)
	json_parser.connect("import_completed", _on_import_completed)
	json_parser.connect("import_error", _on_import_error)
	
func _on_import_button_pressed():
	file_dialog.popup_centered(Vector2(100, 600))


func _on_download_button_pressed():
	# Start the download process
	file_dialog.popup_centered(Vector2(100, 600))
	progress_bar.value = 0
	progress_bar.visible = true
	status_label.text = "Downloading..."
	
	# Start the download process
	var ABCDownloaderScript = load("res://scripts/ABCdownloader.gd")
	var downloader = ABCDownloaderScript.new()
	add_child(downloader)
	await get_tree().process_frame
	downloader.start_download()
	var download_complete = false
	# Wait for the download to complete 
	while not download_complete:
		await downloader.download_completed
		# download_complete = true
		# progress_bar.value = 100
		status_label.text = "Download completed!"
		# progress_bar.visible = false

	var thread = Thread.new()
	thread.start(json_parser.parse_json_file.bind())

func _on_download_progress(current, successful_count, total):
	# Update the progress bar and status label
	var progress = float(current) / float(total) * 100
	progress_bar.value = progress
	status_label.text = "Processed %d of %d tunes (%.1f%%)" % [current, total, progress]

func _on_import_completed():
	download_button.disabled = false
	status_label.text = "download and import completed successfully!"
	progress_bar.value = 100

func _on_import_error(error_message):
	download_button.disabled = false
	status_label.text = "Error: " + error_message
	progress_bar.visible = false

# import_progress.emit(current_count, successful_count, total_count)

### moved over from sqlite    
func _on_build_db_button_pressed():
	show_directory_select_dialog()
	

func show_directory_select_dialog():
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.title = "Select ABC Source Directory"

	# connect directory selected signal
	dialog.dir_selected.connect(_on_directory_selected)
	dialog.canceled.connect(func(): ("Directory selection canceled"))

	add_child(dialog)
	dialog.popup_centered(Vector2(100, 600))

# callback when directory is selected

func _on_directory_selected(path: String):
	print("Selected Directory: ", path)
	ABCImporter.import_files_from_directory(path)

	
	# # Connect signals to handle download progress and completion
	# downloader.connect("download_progress", self, "_on_download_progress")
	# downloader.connect("download_completed", self, "_on_download_completed")
	# downloader.connect("download_error", self, "_on_download_error")

# extends Button
extends PopupPanel

signal import_from_files_selected
signal import_from_session_selected

@onready var import_from_files_button = $VBoxContainer/ImportFromFilesButton
@onready var import_from_session_button = $VBoxContainer/ImportFromSessionButton
@onready var cancel_button = $VBoxContainer/CancelButton

func _ready():
	import_from_files_button.pressed.connect(_on_import_from_files_button_pressed)
	import_from_session_button.pressed.connect(_on_import_from_session_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)

	hide()

func _on_import_from_files_button_pressed():
	emit_signal("import_from_files_selected")
	hide()

func _on_import_from_session_button_pressed():
	emit_signal("import_from_session_selected")
	hide()

func _on_cancel_button_pressed():
	hide()

func show_dialog():
	show()

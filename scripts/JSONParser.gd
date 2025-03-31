extends Node
class_name JSONParser

signal import_progress(current, successful_count, total)
signal import_completed
signal import_error(error_message)

var JSON_FILE_PATH = ProjectSettings.globalize_path("user://session_tunes.json")

var DB_PATH = clientside.prefix + "://assets/data/tunepal.db"

const BATCH_SIZE = 1000 ## process it in batches

const READ_BUFFER_SIZE = 8192 ## 8 KB buffer

var db: SQLite

func _ready():
	initialize_database()

func initialize_database():
	db = SQLite.new()

	db.path = DB_PATH

	var result = db.open_db()
#
	#if result != OK:
		#printerr("Failed to open db ", result)
		#return

func parse_json_file(file):

	var fileaccess = FileAccess.open(file, FileAccess.READ)
	if not fileaccess:
		printerr("failed to open JSON: ", FileAccess.get_open_error())
		return
	
	var char = ""
	while not fileaccess.eof_reached():
		char = fileaccess.get_8()
		if char == "[":
			break

	if fileaccess.eof_reached():
		printerr("Could not find start of json array")
		fileaccess.close()
		return

	print("foudn the start")

	db.query("BEGIN TRANSACTION")

	var tune_json = ""
	var bracket_count = 0 ### how many brackets in are we? nested brackets
	var in_quotes = false
	var escape_next = false
	var tune_count = 0

	while not file.eof_reached():
		char = file.get_8()
		
		# Handle string escaping
		if escape_next:
			escape_next = false
		elif char == "\\":
			escape_next = true
		# Handle quotes
		elif char == "\"" and not escape_next:
			in_quotes = not in_quotes
		# Count brackets only when not in quotes
		elif not in_quotes:
			if char == "{":
				bracket_count += 1
				if bracket_count == 1:
		# Start of a new tune object
					tune_json = "{"
					continue
			elif char == "}":
				bracket_count -= 1
				if bracket_count == 0:
		# End of the tune object, process it
					tune_json += "}"
					process_tunes(tune_json)
					tune_count += 1
					
					# Commit transaction after each batch
					if tune_count % BATCH_SIZE == 0:
						db.query("COMMIT")
						db.query("BEGIN TRANSACTION")
						print("Processed ", tune_count, " tunes")
					
					tune_json = ""
					continue
		
		# Add character to current tune if we're inside a tune object
		if bracket_count > 0:
			tune_json += char

	db.query("COMMIT")
	file.close()
	print("Finished processing ", tune_count, " tunes")

func process_tunes(tune_json_str):
	var json = JSON.new()
	var error = json.parse(tune_json_str)

	if error != OK:
		printerr("Error parsing json ", json.get_error_message())
		return

	var tune = json.get_data()

	# var tools = ABCToolsClass.new()
	var next_id = ABCToolsClass.get_next_tune_id(db)
	# create dictionary of tune data

	var tune_data = {
		id = next_id,
		tunepalid = tune.get("tune_id", ""),
		x = tune.get("setting_id", ""),
		title = tune.get("name", ""),
		tune_type = tune.get("type", ""),
		time_sig = tune.get("meter", ""),
		key_sig = tune.get("meter", ""),
		downloaded = 1,
		source_file = "https://thesession.org/",
		source_id = 10 # placeholder
	}

	return tune_data
### pick up here... i think htis isn't right here
	var query = """
	INSERT OR REPLACE INTO tuneindex (
		id,
		tunepalid,
		file_name,
		x,
		notation,
		title,
		alt_title,
		source,
		tune_type,
		key_sig,
		downloaded,
		time_sig
	) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
	"""

	var params = [
		tune_data["id"], 
		tune_data["tunepalid"], 
		tune_data["source_file"], 
		tune_data["x"], 
		tune_data["abc"],
		tune_data["title"],
		"",
		tune_data["source_id"],
		tune_data["tune_type"],
		tune_data["key_sig"],
		tune_data["downloaded"],
		tune_data["time_sig"],
	]

	db.query_with_bindings(query, params)
	# var db_result = db.query_result
	# if db_result.size() > 0 and db_result[0]["count"] > 0:
	#     print("Duplicate tune found: " + tune["title"])
	#     db.close_db()
	#     return false
	# else:
	#     print("Inserted tune: ", tune["title"])
	#     db.close_db()
	#     return true
	# db.close_db()

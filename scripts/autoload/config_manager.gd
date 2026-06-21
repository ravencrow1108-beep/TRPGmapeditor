##
## ConfigManager — Persistent key-value configuration autoload
## Stores settings in user://config.json.
##
extends Node

const CONFIG_PATH := "user://config.json"

var _config: Dictionary = {}


func _ready() -> void:
	load_config()


## Retrieve a config value, returning `default` if the key is not set.
func get_value(key: String, default: Variant = null) -> Variant:
	return _config.get(key, default)


## Store a config value. Does not automatically persist — call save_config() to write to disk.
func set_value(key: String, value: Variant) -> void:
	_config[key] = value


## Check if a key exists in the config store.
func has_key(key: String) -> bool:
	return _config.has(key)


## Remove a key from the config store.
func erase_key(key: String) -> void:
	_config.erase(key)


## Load config from disk. Called automatically in _ready().
func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		_config = {}
		return

	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("[ConfigManager] Could not open config file for reading: %s" % CONFIG_PATH)
		return

	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(text)
	if error != OK:
		push_warning("[ConfigManager] JSON parse error in config: %s" % json.get_error_message())
		_config = {}
		return

	var data = json.get_data()
	if data is Dictionary:
		_config = data
	else:
		_config = {}


## Persist config to disk.
func save_config() -> void:
	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[ConfigManager] Could not open config file for writing: %s" % CONFIG_PATH)
		return

	file.store_string(JSON.stringify(_config, "\t"))
	file.close()


## Return a shallow copy of the entire config dictionary.
func get_all() -> Dictionary:
	return _config.duplicate()

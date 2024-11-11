extends Node
class_name AWSAmplify

const CONFIG_AUTH = "auth"
const CONFIG_DATA = "data"

const DEFAULT_CONFIG_PATH := "res://amplify_outputs.json"
const DEFAULT_TOKEN_TIMEOUT := 120

const AWSAmplifyClientClass := preload("./lib/client.gd")
const AWSAmplifyAuthClass := preload("./lib/auth.gd")
const AWSAmplifyDataClass := preload("./lib/data.gd")

var config: Dictionary
@export var client: AWSAmplifyClient
@export var auth: AWSAmplifyAuth
@export var data: AWSAmplifyData

func _init(config_path = DEFAULT_CONFIG_PATH):
	config = get_config(config_path)
	
	client = AWSAmplifyClientClass.new(config)
	
	if config.has(CONFIG_AUTH):
		auth = AWSAmplifyAuthClass.new(client, config[CONFIG_AUTH])
		
		if config.has(CONFIG_DATA):
			data = AWSAmplifyDataClass.new(auth, config[CONFIG_DATA])

func _ready():
	add_child(client)
	if auth:
		add_child(auth)
		
		if data:
			add_child(data)
		
func get_config(config_path) -> Dictionary:
	var file = FileAccess.open(config_path, FileAccess.READ)
	assert(file != null, "File does not exist: " + config_path)
		
	var content = file.get_as_text()
	file.close()
		
	var json = JSON.new()
	var parse_result = json.parse(content)
	
	assert(parse_result == OK, "Unable to parse file: " + config_path)
		
	return json.get_data()

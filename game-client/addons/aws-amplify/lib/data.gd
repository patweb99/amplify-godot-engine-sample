extends Node
class_name AWSAmplifyData

const CONFIG_URL = "url"

var auth: AWSAmplifyAuth
var config: Dictionary
var endpoint: String

func _init(_auth: AWSAmplifyAuth, _config: Dictionary) -> void:
	auth = _auth
	config = _config
	endpoint = config[CONFIG_URL]

func mutate(query, operation_name):
	var headers = [
		"Content-Type: application/json"
	]
	
	var body = JSON.stringify({
		"query": "mutation " + operation_name + " " + query,
		"variables": null,
		"operationName": operation_name
	})
	
	return await auth.make_authenticated_request(endpoint, headers, HTTPClient.METHOD_POST, body)

func query(query, operation_name):
	var headers = [
		"Content-Type: application/json"
	]
	
	var body = JSON.stringify({
		"query": "query " + operation_name + " " + query,
		"variables": null,
		"operationName": operation_name
	})
	
	return await auth.make_authenticated_request(endpoint, headers, HTTPClient.METHOD_POST, body)

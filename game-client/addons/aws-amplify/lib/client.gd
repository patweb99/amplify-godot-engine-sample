extends Node
class_name AWSAmplifyClient

var config: Dictionary

func _init(_config) -> void:
	config = _config
	
func make_request(endpoint, headers, method, body):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(endpoint, headers, method, body)
	if error != OK:
		return generate_response_json(false, "Failed to send request", 400, null, error)
		
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result = response[0]
	var response_code = response[1]
	var response_headers = response[2]
	var response_body = response[3]
	
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		if !json:
			if response_code >= 200 && response_code < 300:
				return generate_response_json(true, "Response not in json", response_code, response_headers, result)
			return generate_response_json(false, "Failed to parse the response body", response_code, response_headers, result)
		if response_code != 200:
			return generate_response_json(false, json, response_code, response_headers, result)
		return generate_response_json(true, json, response_code, response_headers, result)
	else:
		return generate_response_json(false, response_body, response_code, response_headers, result)
		
		
func generate_response_json(success, response_body, response_code, response_headers, result):
	return {
		"success": success,
		"response_body": response_body,
		"response_code": response_code,
		"response_headers": response_headers,
		"result": result
	}

extends Node
class_name AWSAmplifyAuth

const CONFIG_REGION = "aws_region"
const CONFIG_CLIENT_ID = "user_pool_client_id"

const BODY_USER_ATTRIBUTES = "UserAttributes"
const BODY_AUTHENTICATED_RESULT = "AuthenticationResult"
const BODY_ACCESS_TOKEN = "AccessToken"
const BODY_REFRESH_TOKEN = "RefreshToken"

const DEFAULT_TOKEN_TIMEOUT = 120

var client: AWSAmplifyClient
var config: Dictionary
var endpoint: String
var client_id: String
var token_timeout = 120

var access_token
var refresh_token
var current_user

signal user_connected
signal user_disconnected

func _init(_client: AWSAmplifyClient, _config: Dictionary, _token_timeout = DEFAULT_TOKEN_TIMEOUT) -> void:
	client = _client
	config = _config
	client_id = config[CONFIG_CLIENT_ID]
	endpoint = "https://cognito-idp." + config[CONFIG_REGION] + ".amazonaws.com/"
	token_timeout = _token_timeout

func sign_in_with_user_password(email, password):
	var headers = [
		"X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth",
		"Content-Type: application/x-amz-json-1.1"
	]
	
	var body = JSON.stringify({
		"AuthFlow": "USER_PASSWORD_AUTH",
		"ClientId": client_id,
		"AuthParameters": {
			"USERNAME": email,
			"PASSWORD": password
		}
	})
	
	var response = await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, body)
	if response.success:
		var response_body = response.response_body
		if response_body.has(BODY_AUTHENTICATED_RESULT) and response_body[BODY_AUTHENTICATED_RESULT].has(BODY_ACCESS_TOKEN):
			
			var authenticated_body = response_body[BODY_AUTHENTICATED_RESULT]
			access_token = authenticated_body[BODY_ACCESS_TOKEN]
			refresh_token = authenticated_body[BODY_REFRESH_TOKEN]
			
			var user = await get_current_user()
			if !user:
				return false
			current_user = user
			user_connected.emit(current_user)
			return response
		
	return response
	
func forgot_password(email):
	
	var headers = [
		"X-Amz-Target: AWSCognitoIdentityProviderService.ForgotPassword",
		"Content-Type: application/x-amz-json-1.1"
	]

	var parameters = {
		"Username": email,
		"ClientId": client_id
	}

	var body = JSON.stringify(parameters)
	
	return await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, body)

func forgot_password_confirm_code(email, confirmation_code, new_password):
	
	var headers = [
		"X-Amz-Target: AWSCognitoIdentityProviderService.ConfirmForgotPassword",
		"Content-Type: application/x-amz-json-1.1"
	]

	var parameters = {
		"Username": email,
		"ClientId": client_id,
		"ConfirmationCode": confirmation_code,
		"Password": new_password
	}

	var body = JSON.stringify(parameters)
	
	return await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, body)

func sign_out():
	user_disconnected.emit(current_user)
	return true
	
func sign_up(email, password, options = {}):
	var headers = [
		"X-Amz-Target: AWSCognitoIdentityProviderService.SignUp",
		"Content-Type: application/x-amz-json-1.1"
	]

	var parameters = {
		"Username": email,
		"Password": password,
		"ClientId": client_id
	}

	if !options.is_empty() && options.has("userAttributes"):
		var userAttributes = options.userAttributes
		var userAttributesArray = []

		for key in userAttributes:
			userAttributesArray.append({
				"Name": key,
				"Value": userAttributes[key]
			})

		parameters[BODY_USER_ATTRIBUTES] = userAttributesArray
	
	var body = JSON.stringify(parameters)
	
	return await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, body)

func sign_up_confirm_code(email, confirmation_code):
	
	var headers = [
		"X-Amz-Target: AWSCognitoIdentityProviderService.ConfirmSignUp",
		"Content-Type: application/x-amz-json-1.1"
	]

	var parameters = {
		"Username": email,
		"ClientId": client_id,
		"ConfirmationCode": confirmation_code
	}

	var body = JSON.stringify(parameters)
	
	return await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, body)

func sign_up_resend_code(email):
	
	var headers = [
		"X-Amz-Target: AWSCognitoIdentityProviderService.ResendConfirmationCode",
		"Content-Type: application/x-amz-json-1.1"
	]

	var parameters = {
		"Username": email,
		"ClientId": client_id
	}

	var body = JSON.stringify(parameters)
	
	return await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, body)


func refresh_access_token():
	
	if !refresh_token || refresh_token == '':
		return false
	
	var headers = [
		"X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth",
		"Content-Type: application/x-amz-json-1.1"
	]
	
	var body = JSON.stringify({
		"AuthFlow": "REFRESH_TOKEN_AUTH",
		"ClientId": client_id,
		"AuthParameters": {
			"REFRESH_TOKEN": refresh_token
		}
	})
	
	var response = await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, body)
	var response_body = response.response_body
	if response_body.has(BODY_AUTHENTICATED_RESULT) and response_body.AuthenticationResult.has(BODY_ACCESS_TOKEN):
		access_token = response_body[BODY_AUTHENTICATED_RESULT][BODY_ACCESS_TOKEN]

	return response
	
	
func get_current_user():
	
	if current_user:
		return current_user
		
	#Add an token helper function to verify there is a token
	
	var headers = [
		"X-Amz-Target: AWSCognitoIdentityProviderService.GetUser",
		"Content-Type: application/x-amz-json-1.1"
	]
	
	var body = JSON.stringify({
		BODY_ACCESS_TOKEN: access_token,
	})

	var response = await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, body)
	var response_body = response.response_body
	
	if response_body.has(BODY_USER_ATTRIBUTES):
		var user_attributes = response_body[BODY_USER_ATTRIBUTES]
		
		var user = {}
		for item in user_attributes: # create util function for this?
			user[item.Name] = item.Value
		user.Username = response_body.Username
		return user
		
	return false
	
func get_user_attribute(attribute):
	if current_user == null:
		print("No current user")
		return null
	
	if not current_user.has(attribute):
		print("User does not have attribute attribute")
		return null
	
	var attribute_value = current_user[attribute]
	if attribute_value == null:
		print("attribute is null")
		return null
	
	return attribute_value
	
func handle_authentication():
	if !refresh_token || refresh_token == '':
		return {"success": false, "message": "User in not authenticated"}
	
	if !access_token || access_token == '':
		print("refreshing access token 1")
		var success = await refresh_access_token()
		if !success:
			return {"success": false, "message": "Couldn't retrieve refresh token"}
		
	var expiration_delay = get_token_expiration_delay(access_token)
	print("token expiring in : ", expiration_delay)
	if expiration_delay < token_timeout:
		print("refreshing access token 2")
		var success = await refresh_access_token()
		if !success:
			return {"success": false, "message": "Couldn't retrieve refresh token"}
			
	return {"success": true, "message": "Succesfully retrieved access token"}

func decode_jwt(token):
	var parts = token.split(".")
	if parts.size() != 3:
		return {}
	
	var header = JSON.parse_string(Marshalls.base64_to_utf8(parts[0]))
	var payload = JSON.parse_string(Marshalls.base64_to_utf8(parts[1]))
	
	return {"header": header, "payload": payload}
	
func get_token_expiration_delay(token):
	#error handling to be added
	
	var decoded_token = decode_jwt(token)
	var token_payload = decoded_token.payload

	return token_payload.exp - Time.get_unix_time_from_system()

func _make_authenticated_request(endpoint, headers, method, body):
	var authentication_result = await handle_authentication()
	print(authentication_result)
	if !authentication_result.success:
		client.generate_response_json(authentication_result.success, authentication_result.message, 401, null, -1)
	
	headers.append("Authorization: Bearer " + access_token)
	return await client.make_request(endpoint, headers, method, body)

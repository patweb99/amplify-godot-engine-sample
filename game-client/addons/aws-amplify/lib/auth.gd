extends Node
class_name AWSAmplifyAuth

class CONFIG:
	const REGION = "aws_region"
	const CLIENT_ID = "user_pool_client_id"

class HEADERS:
	const CONTENT_TYPE = "Content-Type: application/x-amz-json-1.1"
	static func X_AMZ_TARGET(target) -> String:
		return "X-Amz-Target: AWSCognitoIdentityProviderService." + target
	static func AUTHORIZATION_BEARER(access_token) -> String:
		return "Authorization: Bearer" + access_token

class BODY:
	const CLIENT_ID = "ClientId"
	const AUTH_FLOW = "AuthFlow"
	const AUTH_PARAMETERS = "AuthParameters"
	const USERNAME = "Username"
	const PASSWORD = "Password"
	const CONFIRMATION_CODE = "ConfirmationCode"
	const USER_ATTRIBUTES = "UserAttributes"
	const AUTHENTICATED_RESULT = "AuthenticationResult"
	const ACCESS_TOKEN = "AccessToken"
	const REFRESH_TOKEN = "RefreshToken"

class TOKEN:
	const ACCESS_TOKEN = "AccessToken"
	const ACCESS_TOKEN_EXPIRATION_TIME = "AccessTokenExpirationTime"
	const REFRESH_TOKEN = "RefreshToken"	

class USER:
	const EMail = "Email"

var client: AWSAmplifyClient
var config: Dictionary
var endpoint: String
var client_id: String

var tokens: Dictionary
var user_attributes: Dictionary

signal user_signed_in
signal user_refreshed
signal user_signed_out
signal user_signed_up

func _init(_client: AWSAmplifyClient, _config: Dictionary) -> void:
	client = _client
	config = _config
	client_id = config[CONFIG.CLIENT_ID]
	endpoint = "https://cognito-idp." + config[CONFIG.REGION] + ".amazonaws.com/"
	tokens = {}
	user_attributes = {}

func is_user_signed_in():
	return tokens[TOKEN.ACCESS_TOKEN] != null && _get_access_token_expiration_time(tokens[TOKEN.ACCESS_TOKEN]) < Time.get_unix_time_from_system()

func get_user_attributes(refresh_attributes = false):
	refresh_user(refresh_attributes)
	return user_attributes
	
func get_user_access_token_expiration_time() -> int:
	if tokens.has(TOKEN.ACCESS_TOKEN):
		return _get_access_token_expiration_time(tokens[TOKEN.ACCESS_TOKEN])
	else:
		return Time.get_unix_time_from_system()
	
func add_user_attributes(_user_attributes: Dictionary = {}):
	var attributes = user_attributes
	attributes.merge(_user_attributes)
	update_user_attributes(attributes)
	
func remove_user_attributes(keys: Array):
	var attributes = user_attributes
	for key in user_attributes.keys():
		if not keys.has(key):
			attributes[key] = user_attributes[key]
	update_user_attributes(attributes)

func update_user_attributes(_user_attributes: Dictionary = {}):
	var attributes = _user_attributes
	for key in attributes.keys():
		attributes.append({
			"Name": key,
			"Value": attributes[key]
		})
	
	var headers = [
		HEADERS.X_AMZ_TARGET("UpdateUserAttributes"),
		HEADERS.CONTENT_TYPE
	]
	
	var body = {
		BODY.CLIENT_ID: client_id,
		BODY.USER_ATTRIBUTES: attributes
	}
	
	var response = await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if response.success:
		user_attributes = _user_attributes
		user_refreshed.emit(user_attributes)
	return response

func refresh_user(refresh_access_token = false, refresh_attributes = false):
	if tokens[TOKEN.ACCESS_TOKEN]:
		# refresh user access token if user access token has expired
		if refresh_access_token or (tokens[TOKEN.ACCESS_TOKEN_EXPIRATION_TIME] > Time.get_unix_time_from_system() and tokens[TOKEN.REFRESH_TOKEN]):
			var response = await _refresh_user_access_token(tokens[TOKEN.REFRESH_TOKEN])
			if not response.success:
				_clean_tokens()
		else:
			_clean_tokens()
		
		# refresh user attributes
		if refresh_attributes:
			var response = await _refresh_user_attributes(tokens[TOKEN.ACCESS_TOKEN])
			if response.success:
				user_refreshed.emit(user_attributes)
			else:
				_clean_tokens()
		else:
			user_refreshed.emit(user_attributes)
			
	else:
		_clear_user_attributes()

func sign_in_with_user_password(email, password):
	var headers = [
		HEADERS.X_AMZ_TARGET("InitiateAuth"),
		HEADERS.CONTENT_TYPE
	]
	
	var body = {
		BODY.CLIENT_ID: client_id,
		BODY.AUTH_FLOW: "USER_PASSWORD_AUTH",
		BODY.AUTH_PARAMETERS: {
			"USERNAME": email,
			"PASSWORD": password
		}
	}

	var response = await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if response.success:
		user_attributes = {}
		user_attributes[USER.EMail] = email
		
		var response_body = response.response_body
		if response_body.has(BODY.AUTHENTICATED_RESULT) and response_body[BODY.AUTHENTICATED_RESULT].has(BODY.ACCESS_TOKEN):
			
			var authenticated_result = response_body[BODY.AUTHENTICATED_RESULT]
			tokens[TOKEN.ACCESS_TOKEN] = authenticated_result[BODY.ACCESS_TOKEN]
			tokens[TOKEN.ACCESS_TOKEN_EXPIRATION_TIME] = _get_access_token_expiration_time(tokens[TOKEN.ACCESS_TOKEN])
			tokens[TOKEN.REFRESH_TOKEN] = authenticated_result[BODY.REFRESH_TOKEN]
			
			var refresh_user_attributes_response = await _refresh_user_attributes(tokens[TOKEN.ACCESS_TOKEN])
			if refresh_user_attributes_response.success:
				user_signed_in.emit(user_attributes)
			else:
				_clear_user_attributes()
			return refresh_user_attributes_response
		
	return response

func forgot_password(email):
	var headers = [
		HEADERS.X_AMZ_TARGET("ForgotPassword"),
		HEADERS.CONTENT_TYPE
	]

	var body = {
		BODY.CLIENT_ID: client_id,
		BODY.USERNAME: email
	}

	return await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func forgot_password_confirm_code(email, confirmation_code, new_password):
	var headers = [
		HEADERS.X_AMZ_TARGET("ConfirmForgotPassword"),
		HEADERS.CONTENT_TYPE
	]

	var body = {
		BODY.CLIENT_ID: client_id,
		BODY.USERNAME: email,
		BODY.CONFIRMATION_CODE: confirmation_code,
		BODY.PASSWORD: new_password
	}

	return await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func global_sign_out():
	var headers = [
		HEADERS.X_AMZ_TARGET("GlobalSignOut"),
		HEADERS.CONTENT_TYPE
	]

	var body = {
		BODY.CLIENT_ID: client_id,
		BODY.ACCESS_TOKEN: tokens[TOKEN.ACCESS_TOKEN]
	}
	
	var response = await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if response.success:
		user_signed_out.emit(user_attributes)
		_clean_tokens()
	return response
	
func sign_up(email, password, options = {}):
	var headers = [
		HEADERS.X_AMZ_TARGET("SignUp"),
		HEADERS.CONTENT_TYPE
	]

	var body = {
		BODY.CLIENT_ID: client_id,
		BODY.USERNAME: email,
		BODY.PASSWORD: password
	}

	if !options.is_empty() && options.has("userAttributes"):
		var userAttributes = options["userAttributes"]
		var userAttributesArray = []

		for key in userAttributes:
			userAttributesArray.append({
				"Name": key,
				"Value": userAttributes[key]
			})

		body[BODY.USER_ATTRIBUTES] = userAttributesArray
	
	var response = await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if response.success:
		user_signed_up.emit()
	return response

func sign_up_confirm_code(email, confirmation_code):
	var headers = [
		HEADERS.X_AMZ_TARGET("ConfirmSignUp"),
		HEADERS.CONTENT_TYPE
	]

	var body = {
		BODY.CLIENT_ID: client_id,
		BODY.USERNAME: email,
		BODY.CONFIRMATION_CODE: confirmation_code
	}

	return await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func sign_up_resend_code(email):
	var headers = [
		HEADERS.X_AMZ_TARGET("ResendConfirmationCode"),
		HEADERS.CONTENT_TYPE
	]

	var body = {
		BODY.CLIENT_ID: client_id,
		BODY.USERNAME: email
	}
	
	return await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func make_authenticated_request(endpoint, headers, method, body):
	refresh_user(false)
	headers.append(HEADERS.AUTHORIZATION_BEARER(tokens[TOKEN.ACCESS_TOKEN]))
	return await client.make_request(endpoint, headers, method, body)

func _refresh_user_access_token(refresh_token):
	var headers = [
		HEADERS.X_AMZ_TARGET("InitiateAuth"),
		HEADERS.CONTENT_TYPE
	]
	
	var body = {
		BODY.CLIENT_ID: client_id,
		BODY.AUTH_FLOW:"REFRESH_TOKEN_AUTH",
		BODY.AUTH_PARAMETERS: {
			"REFRESH_TOKEN": refresh_token
		}
	}
	
	var response = await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	var response_body = response.response_body
	if response_body.has(BODY.AUTHENTICATED_RESULT) and response_body[BODY.AUTHENTICATED_RESULT].has(BODY.ACCESS_TOKEN):
		tokens[TOKEN.ACCESS_TOKEN] = response_body[BODY.AUTHENTICATED_RESULT][BODY.ACCESS_TOKEN]
		tokens[TOKEN.ACCESS_TOKEN_EXPIRATION_TIME] = _get_access_token_expiration_time(tokens[TOKEN.ACCESS_TOKEN])
	return response
	
func _refresh_user_attributes(access_token):
	var headers = [
		HEADERS.X_AMZ_TARGET("GetUser"),
		HEADERS.CONTENT_TYPE
	]
	
	var body = {
		BODY.ACCESS_TOKEN: access_token,
	}

	var response = await client.make_request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if response.success:
		var user_attributes = response.response_body[BODY.USER_ATTRIBUTES]
		var user = {}
		for user_attribute in user_attributes:
			user[user_attribute.Name] = user_attribute.Value
	return response

func _clean_tokens():
	tokens.clear()
	_clear_user_attributes()

func _clear_user_attributes():
	user_attributes.clear()
	user_refreshed.emit(user_attributes)

func _get_access_token_expiration_time(access_token):
	var decoded_token = _decode_jwt(access_token)
	var token_payload = decoded_token.payload
	return token_payload.exp

func _decode_jwt(token):
	var parts = token.split(".")
	if parts.size() != 3:
		return {}
	
	var header = JSON.parse_string(Marshalls.base64_to_utf8(parts[0]))
	var payload = JSON.parse_string(Marshalls.base64_to_utf8(parts[1]))
	
	return {"header": header, "payload": payload}

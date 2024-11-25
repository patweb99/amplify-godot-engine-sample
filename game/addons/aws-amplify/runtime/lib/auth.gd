class_name AWSAmplifyAuth  
extends AWSAmplifyBase

signal user_signed_in
signal user_changed
signal user_signed_out
signal user_signed_up

#
# SignUp
#
# sign_up(
#	<user_email> or <user_phone_number>,
#   <user_password>,
#	{
#		userAttributes: {
#			email: <user_email>,
#			phone_number: <user_phone_number>
#		}
#	}
#)
#

class AuthSignUpOutput:
	var is_sign_up_complete: bool
	var user_id: String
	
func sign_up(username, password, options: Dictionary = {}):
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("SignUp"),
	]

	var user_attributes = _options_to_dictionary(AuthOptions.USER_ATTRIBUTES, options)
	var username_attribute = get_username_attribute()
	user_attributes[username_attribute] = username
	
	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.USERNAME: username,
		BODY.PASSWORD: password,
		BODY.USER_ATTRIBUTES: _dictionary_to_array(user_attributes)
	}

	var response = await _client.make_http_post(_endpoint, headers, body)
	
	if response.success:
		user_signed_up.emit()

	return response

#
# ConfirmSignUp
#

func confirm_sign_up(username: String, confirmation_code: String, options: Dictionary = {}):
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("ConfirmSignUp")
	]

	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.USERNAME: username,
		BODY.CONFIRMATION_CODE: confirmation_code,
		BODY.USER_ATTRIBUTES: _options_to_array(AuthOptions.USER_ATTRIBUTES, options)
	}

	return await _client.make_http_post(_endpoint, headers, body)

#
# ResendSignUpCode
#

func resend_sign_up_code(username, options: Dictionary = {}):
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("ResendConfirmationCode")
	]

	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.USERNAME: username,
		BODY.USER_ATTRIBUTES: _options_to_array(AuthOptions.USER_ATTRIBUTES, options)
	}
	
	return await _client.make_http_post(_endpoint, headers, body)

#
# IsSignedIn
#

func is_signed_in():
	return (
		_tokens.has(TOKEN.ACCESS_TOKEN) && 
		_token_expiration_time(_tokens[TOKEN.ACCESS_TOKEN]) > Time.get_unix_time_from_system()
	)

#
# SignIn
# 

func sign_in(username, password, options: Dictionary = {}):
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("InitiateAuth")
	]
	
	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.AUTH_FLOW: "USER_PASSWORD_AUTH",
		BODY.AUTH_PARAMETERS: {
			"USERNAME": username,
			"PASSWORD": password
		},
		BODY.USER_ATTRIBUTES: _options_to_array(AuthOptions.USER_ATTRIBUTES, options)
	}

	var response = await _client.make_http_post(_endpoint, headers, body)
	
	if response.success:
		var response_body = response.response_body
		if response_body.has(BODY.AUTHENTICATED_RESULT) and response_body[BODY.AUTHENTICATED_RESULT].has(BODY.ACCESS_TOKEN):
			
			var authenticated_result = response_body[BODY.AUTHENTICATED_RESULT]
			_tokens.set_all(authenticated_result)

			var user_attributes = await fetch_user_attributes()
			if _user_attributes:
				_user_attributes.set_all(user_attributes)
				user_signed_in.emit(_user_attributes)
			else:
				_clear_user_attributes()
		
	return response

#
# ResetPassword
#

func reset_password(username, options: Dictionary = {}):
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("ForgotPassword")
	]

	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.USERNAME: username,
		BODY.USER_ATTRIBUTES: _options_to_array(AuthOptions.USER_ATTRIBUTES, options)
	}

	return await _client.make_http_post(_endpoint, headers, body)

#
# ConfirmResetPassword
#

func confirm_reset_password(username, new_password, confirmation_code, options: Dictionary = {}):
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("ConfirmForgotPassword")
	]

	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.USERNAME: username,
		BODY.PASSWORD: new_password,
		BODY.CONFIRMATION_CODE: confirmation_code
	}

	return await _client.make_http_post(_endpoint, headers, body)

#
# UpdatePassword
#

func update_password(old_password, new_password, options: Dictionary = {}):
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("UpdatePassword")
	]

	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.ACCESS_TOKEN: _tokens[TOKEN.ACCESS_TOKEN],
		BODY.PREVIOUS_PASSWORD: old_password,
		BODY.PROPOSED_PASSWORD: new_password
	}

	return await make_authenticated_http_post(_endpoint, headers, body)

#
# UpdateUserAttributes
#

func update_user_attributes(user_attributes: Dictionary, options: Dictionary = {}):
	
	var headers = [
		AWSAmplifyBase.HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		AWSAmplifyBase.HEADERS.X_AMZ_TARGET("UpdateUserAttributes")
	]
	
	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.ACCESS_TOKEN: _tokens[TOKEN.ACCESS_TOKEN],
		BODY.USER_ATTRIBUTES: _dictionary_to_array(user_attributes)
	}

	var response = await _client.make_http_post(_endpoint, headers, body)
	
	if response.success:
		_user_attributes.merge(user_attributes, true)
		user_changed.emit(_user_attributes)
		
	return response

#
# UpdateUserAttribute
#

func update_user_attribute(user_attribute_name: String, user_attribute_value, options: Dictionary = {}):
	return await update_user_attributes({ user_attribute_name: user_attribute_value }, options)

#
# ConfirmUserAttribute
#

func confirm_user_attribute(attribute_name: String, confirmation_code: String, options: Dictionary = {}):
	
	var headers = [
		AWSAmplifyBase.HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		AWSAmplifyBase.HEADERS.X_AMZ_TARGET("VerifyUserAttribute"),
	]
	
	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.ACCESS_TOKEN: _tokens[TOKEN.ACCESS_TOKEN],
		BODY.ATTRIBUTE_NAME: attribute_name,
		BODY.CONFIRMATION_CODE: confirmation_code
	}

	return await _client.make_http_post(_endpoint, headers, body)

#
# SendUserAttributeConfirmationCode
#

func send_user_attribute_confirmation_code(attribute_name: String, confirmation_code: String, options: Dictionary = {}):
	
	var headers = [
		AWSAmplifyBase.HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		AWSAmplifyBase.HEADERS.X_AMZ_TARGET("GetUserAttributeVerificationCode"),
	]
	
	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.ACCESS_TOKEN: _tokens[TOKEN.ACCESS_TOKEN],
		BODY.ATTRIBUTE_NAME: attribute_name
	}

	return await _client.make_http_post(_endpoint, headers, body)

#
# DeleteUserAttributes
#

func delete_user_attributes(user_attribute_names: Array[String]):
	
	var headers = [
		AWSAmplifyBase.HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		AWSAmplifyBase.HEADERS.X_AMZ_TARGET("UpdateUserAttributes")
	]
	
	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.ACCESS_TOKEN: _tokens[TOKEN.ACCESS_TOKEN],
		BODY.USER_ATTRIBUTE_NAMES: user_attribute_names
	}

	var response = await _client.make_http_post(_endpoint, headers, body)
	
	if response.success:
		for user_attribute_name in user_attribute_names:
			_user_attributes[user_attribute_name] = null
		user_changed.emit(_user_attributes)
		
	return response

#
# FetchUserAttributes
#

func fetch_user_attributes() :
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("GetUser"),
	]
	
	var body = {
		BODY.ACCESS_TOKEN: _tokens[TOKEN.ACCESS_TOKEN]
	}

	var response = await _client.make_http_post(_endpoint, headers, body)
	if response.success:
		var attributes = response.response_body[BODY.USER_ATTRIBUTES]
		return _array_to_dictionary(attributes)
	else:	
		return {}

#
# SignOut
#

func sign_out(global: bool = false):
	
	if global:
		return await global_sign_out()
	else:
		return await revoke_token()

#
# GlobalSignOut
#

func global_sign_out():
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,		
		HEADERS.X_AMZ_TARGET("GlobalSignOut")
	]

	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.ACCESS_TOKEN: _tokens[TOKEN.ACCESS_TOKEN]
	}
	
	var response = await _client.make_http_post(_endpoint, headers, body)
	if response.success:
		user_signed_out.emit(_user_attributes)
		_clear_tokens()
		
	return response

#
# RevokeToken
#

func revoke_token():

	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,		
		HEADERS.X_AMZ_TARGET("RevokeToken")
	]

	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_ID],
		BODY.CLIENT_SECRET: _config[CONFIG.CLIENT_SECRET],
		BODY.ACCESS_TOKEN: _tokens[TOKEN.ACCESS_TOKEN]
	}
	
	var response = await _client.make_http_post(_endpoint, headers, body)
	if response.success:
		user_signed_out.emit(_user_attributes)
		_clear_tokens()
		
	return response

#
# RefrehsToken
#

func refresh_token(refresh_token):
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("InitiateAuth")
	]
	
	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_SECRET],
		BODY.AUTH_FLOW:"REFRESH_TOKEN_AUTH",
		BODY.AUTH_PARAMETERS: {
			"REFRESH_TOKEN": refresh_token
		}
	}
	
	var response = await _client.make_http_post(_endpoint, headers, body)
	if response.success:
		var response_body = response.response_body
		if response_body.has(BODY.AUTHENTICATED_RESULT) and response_body[BODY.AUTHENTICATED_RESULT].has(BODY.ACCESS_TOKEN):
			var authenticated_result = response_body[BODY.AUTHENTICATED_RESULT]
			_tokens.set_all(authenticated_result)
			
	return response

#
# GetToken
#

func get_token(name):
	if _tokens.has(name):
		return _tokens[name]
	else:
		return null

#
# GetTokenExpirationTime
#

func get_token_expiration_time() -> int:
	if _tokens.has(TOKEN.ACCESS_TOKEN):
		return _token_expiration_time(_tokens[TOKEN.ACCESS_TOKEN])
	else:
		return 0

#
# DeleteUser
#

func delete_user():
	
	var headers = [
		HEADERS.CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1,
		HEADERS.X_AMZ_TARGET("DeleteUser")
	]
	
	var body = {
		BODY.CLIENT_ID: _config[CONFIG.CLIENT_SECRET],
		BODY.ACCESS_TOKEN: _tokens[TOKEN.ACCESS_TOKEN]
	}
	
	return await _client.make_http_post(_endpoint, headers, body)

#
# GetUserAttribute
#

func get_user_attribute(name: String, refresh_attributes = false):
	var attributes = get_user_attributes(refresh_attributes)
	if attributes.has(name):
		return attributes[name]
	else:
		return null

#
# GetUserAttributes
#

func get_user_attributes(refresh_attributes = false):
	refresh_user(refresh_attributes)
	return _user_attributes

#
# AddUserAttributes
#

func add_user_attributes(user_attributes: Dictionary):
	var response = await update_user_attributes(user_attributes)
	if response.success:
		_user_attributes.merge(user_attributes)
		user_changed.emit(_user_attributes)

#
# RemoveUserAttributes
#

func remove_user_attributes(keys: Array):
	var response = await delete_user_attributes(keys)
	if response.success:
		for key in keys:
			_user_attributes.erase(key)
		user_changed.emit(_user_attributes)

#
# RefreshUser
#

func refresh_user(refresh_token = false, refresh_user_attributes = false):
	
	if _tokens.has(TOKEN.ACCESS_TOKEN):
		var token_expiration_time = _token_expiration_time(_tokens[TOKEN.ACCESS_TOKEN])
		
		# refresh user access token if user access token has expired
		if (refresh_token or 
			(token_expiration_time < Time.get_unix_time_from_system() 
			and _tokens[TOKEN.REFRESH_TOKEN])):
			var response = await refresh_token(_tokens[TOKEN.REFRESH_TOKEN])
			if not response.success:
				_clear_tokens()
		
		# refresh user attributes
		if refresh_user_attributes:
			_user_attributes = await fetch_user_attributes()
			if _user_attributes:
				user_changed.emit(_user_attributes)
			else:
				_clear_tokens()
		else:
			user_changed.emit(_user_attributes)
	else:
		_clear_user_attributes()

#
# GetUsernameAttribute
#

func get_username_attribute():
	if _config.has(CONFIG.USERNAME_ATTRIBUTES):
		var username_attributes = _config[CONFIG.USERNAME_ATTRIBUTES]
		return username_attributes[0]
	else:
		return USER_ATTRIBUTES.EMAIL

func make_authenticated_http_get(endpoint, headers, body):
	return await make_authenticated_http_request(endpoint, headers, HTTPClient.METHOD_GET , body)

func make_authenticated_http_post(endpoint, headers, body):
	return await make_authenticated_http_request(endpoint, headers, HTTPClient.METHOD_POST, body)

func make_authenticated_http_put(endpoint, headers, body):
	return await make_authenticated_http_request(endpoint, headers, HTTPClient.METHOD_PUT, body)

func make_authenticated_http_delete(endpoint, headers, body):
	return await make_authenticated_http_request(endpoint, headers, HTTPClient.METHOD_DELETE, body)

func make_authenticated_http_request(endpoint, headers, method, body):
	# automatically refresh access token if expired
	refresh_user()
	# append access token to the authorization bearer
	headers.append(HEADERS.AUTHORIZATION_BEARER(_tokens[TOKEN.ACCESS_TOKEN]))
	return await _client.make_http_request(endpoint, headers, method, body)

var _client: AWSAmplifyClient
var _config: Dictionary
var _endpoint: String
var _tokens: AuthStore
var _user_attributes: AuthStore

func _init(client: AWSAmplifyClient, config: Dictionary) -> void:
	_client = client
	_config = config
	_endpoint = "https://cognito-idp." + config[CONFIG.REGION] + ".amazonaws.com/"
	_tokens = AuthMemoryStore.new()
	_user_attributes = AuthMemoryStore.new()

func _clear_tokens():
	_tokens.clear()
	_clear_user_attributes()

func _clear_user_attributes():
	_user_attributes.clear()
	user_changed.emit(_user_attributes)

func _token_expiration_time(access_token):
	var decoded_token = _decode_jwt(access_token)
	var token_payload = decoded_token[JWT.PAYLOAD]
	return token_payload.exp

func _decode_jwt(token):
	var parts = token.split(".")
	
	assert(parts.size() == 3, "JWT Token must have 3 parts: header, payload and verified signature.")
	
	var header_byte_array = _base64URL_decode(parts[0])
	var header = _parse_json(header_byte_array)
	var payload_string = _base64URL_decode(parts[1])
	var payload = _parse_json(payload_string)
	
	return {
		JWT.HEADER: header, 
		JWT.PAYLOAD: payload
	}
	
func _base64URL_decode(input: String) -> PackedByteArray:
	match (input.length() % 4):
		2: input += "=="
		3: input += "="
	return Marshalls.base64_to_raw(input.replacen("_","/").replacen("-","+"))

func _parse_json(field: PackedByteArray) -> Dictionary:
	return JSON.parse_string(field.get_string_from_utf8())

func _options_to_dictionary(name: String, options: Dictionary) -> Dictionary:
	var dictionary = {}
	if options.has(name):
		dictionary = options[name]
	return dictionary

func _options_to_array(name: String, options: Dictionary) -> Array:
	var dictionary = {}
	if options.has(name):
		dictionary = options[name]
	return _dictionary_to_array(dictionary)

func _dictionary_to_array(dictionary: Dictionary) -> Array:
	var array = []
	for key in dictionary:
		array.append({
			"Name": key,
			"Value": dictionary[key]
		})
	return array

func _array_to_dictionary(array: Array) -> Dictionary:
	var dictionary = {}
	for entry in array:
		dictionary[entry.Name] = entry.Value
	return dictionary

#
# AuthStore
#

class AuthStore:
	func clear(): _not_implemented_yet()
	func erase(key: Variant) -> bool: return _not_implemented_yet(false)
	func find_key(value: Variant) -> Variant: return _not_implemented_yet(null)
	func _get(key: Variant, default: Variant = null) -> Variant: return _not_implemented_yet(null)
	func get_all() -> Dictionary: return _not_implemented_yet(_empty_dictionary)
	func get_or_add(key: Variant, default: Variant = null) -> Variant: return _not_implemented_yet(null) 
	func has(key: Variant) -> bool: return _not_implemented_yet(false) 
	func has_all(keys: Array) -> bool: return _not_implemented_yet(false)
	func is_empty() -> bool: return _not_implemented_yet(false)
	func keys() -> Array: return _not_implemented_yet(_empty_array) 
	func merge(dict: Dictionary, overwrite: bool = false) -> void: _not_implemented_yet()
	func _set(property: StringName, value: Variant) -> bool: return _not_implemented_yet(false) 
	func set_all(values: Dictionary) -> bool: return _not_implemented_yet(false) 
	func size() -> int: return _not_implemented_yet(-1)
	func values() -> Array: return _not_implemented_yet(_empty_array)
	
	func _not_implemented_yet(value = null):
		assert(false, "Not Implemented Yet!")
		return value
	const _empty_array = []
	const _empty_dictionary = {}

#
# AuthMemoryStore
#

class AuthMemoryStore extends AuthStore:
	func clear(): _dict.clear()
	func erase(key: Variant) -> bool: return _dict.erase(key)
	func find_key(value: Variant) -> Variant: return _dict.find_key(value)
	func _get(key: Variant, default: Variant = null) -> Variant: return _dict.get(key)
	func get_all() -> Dictionary: return _dict
	func get_or_add(key: Variant, default: Variant = null) -> Variant: return _dict.get_or_add(key, default)
	func has(key: Variant) -> bool: return _dict.has(key)
	func has_all(keys: Array) -> bool: return _dict.has_all(keys)
	func is_empty() -> bool: return _dict.is_empty()
	func keys() -> Array: return _dict.keys()
	func merge(dict: Dictionary, overwrite: bool = false) -> void: _dict.merge(dict, overwrite)
	func _set(name: StringName, value: Variant) -> bool: _dict[name] = value; return true
	func set_all(values: Dictionary) -> bool: 
		_dict.clear()
		_dict.merge(values)
		return true
	func size() -> int: return _dict.size()
	func values() -> Array: return _dict.values()
		
	var _dict = {}
	
#
# Constants and types
#

class CONFIG:
	const REGION = "aws_region"
	const CLIENT_ID = "user_pool_client_id"
	const CLIENT_SECRET = "user_pool_client_secret"
	const USERNAME_ATTRIBUTES = "username_attributes"
	const USER_VERIFICATION_TYPE = "user_verification_types"

class TOKEN:
	const ACCESS_TOKEN = "AccessToken"
	const EXPIRES_IN = "AccessTokenExpirationTime"
	const ID_TOKEN = "IdToken"
	const REFRESH_TOKEN = "RefreshToken"
	const TOKEN_TYPE = "TokenType"

class JWT:
	const HEADER = "header"
	const PAYLOAD = "payload"
	const VERIFIED_SIGNATURE = "verified_signature"

class AuthOptions:
	const USER_ATTRIBUTES = "userAttributes"
	const CLIENT_METADATA = "clientMetadata"

enum AuthError {
	NO_CONFIG,
	MISSION_AUTH_CONFIG,
	EMPTY_USERNAME,
	INVALID_USERNAME,
	EMPTY_PASSWORD,
	EMPTY_CODE,
	SIGNUP_ERROR,
	NO_MFA,
	INVALID_MFA,
	EMPTY_CHALLENGE_RESPONSE,
	NO_USER_SESSION,
	DEFAULT,
	DEVICE_CONFIG,
	NETWORK_ERROR,
	AUTO_SIGNIN_ERROR,
	OAUTH_SIGN_IN_ERROR
}

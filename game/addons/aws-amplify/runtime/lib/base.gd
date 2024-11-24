class_name AWSAmplifyBase
extends Node

class HEADERS:
	const CONTENT_TYPE_APPLICATION_X_AMZ_JSON_1_1 = "Content-Type: application/x-amz-json-1.1"
	static func X_AMZ_TARGET(target) -> String:
		return "X-Amz-Target: AWSCognitoIdentityProviderService." + target
	static func AUTHORIZATION_BEARER(access_token) -> String:
		return "Authorization: Bearer " + access_token

class BODY:
	const ACCESS_TOKEN = "AccessToken"
	const ATTRIBUTE_NAME = "AttributeName"
	const AUTH_FLOW = "AuthFlow"
	const AUTH_PARAMETERS = "AuthParameters"
	const AUTHENTICATED_RESULT = "AuthenticationResult"
	const CLIENT_ID = "ClientId"
	const CLIENT_SECRET = "ClientSecret"
	const CLIENT_METADATA = "ClientMetadata"
	const CONFIRMATION_CODE = "ConfirmationCode"
	const PASSWORD = "Password"
	const PREVIOUS_PASSWORD = "PreviousPassword"
	const PROPOSED_PASSWORD = "ProposedPassword"
	const REFRESH_TOKEN = "RefreshToken"
	const USERNAME = "Username"
	const USER_ATTRIBUTES = "UserAttributes"
	const USER_ATTRIBUTE_NAMES = "UserAttributeNames"

class USER_ATTRIBUTES:
	static func CUSTOM(name: String):
		return "custom:" + name
	const NAME = "name"
	const FAMILY_NAME = "family_name"
	const GIVEN_NAME = "given_name"	
	const MIDDLE_NAME = "middle_name"
	const NICKNAME = "nickname"
	const PREFERRED_NAME = "preferred_username"
	const PROFILE = "profile"
	const PICTURE = "picture"
	const WEBSITE = "website"
	const GENDER = "gender"
	const BIRTHDATE = "birthdate"
	const ZONEINFO = "zoneinfo"
	const LOCALE = "locale"
	const UPDATED_AT = "updated_at"
	const ADDRESS = "address"
	const EMAIL = "email"
	const PHONE_NUMBER = "phone_number"
	const SUB = "sub"

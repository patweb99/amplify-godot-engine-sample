class_name AWSAmplifyBase
extends Node

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

class USER_ATTRIBUTES:
	const EMAIL = "email"
	const PHONE_NUMBER = "phone_number"

enum AuthMode {
	EMAIL,
	PHONENUMBER
}

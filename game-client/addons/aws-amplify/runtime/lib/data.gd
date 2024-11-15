class_name AWSAmplifyData
extends AWSAmplifyBase

class CONFIG:
	const URL = "url"

enum GraphQLMethod {
	QUERY,
	MUTATION,
	SUBSCRIPTION
}

var _client: AWSAmplifyClient
var _auth: AWSAmplifyAuth
var _config: Dictionary
var _endpoint: String

func make_graphql_mutation(query, operation_name, authenticated: bool = false):
	return await make_graphql_request(query, operation_name, GraphQLMethod.QUERY, authenticated)

func make_graphql_query(query, operation_name, authenticated: bool = false):
	return await make_graphql_request(query, operation_name, GraphQLMethod.MUTATION, authenticated)

func make_graphql_request(query, operation_name, method: GraphQLMethod, authenticated: bool = false):
	var headers = [
		"Content-Type: application/json"
	]
	
	var query_prefix: String
	if method == GraphQLMethod.QUERY:
		query_prefix = "query "
	elif method == GraphQLMethod.MUTATION:
		query_prefix = "mutation "
	elif method == GraphQLMethod.SUBSCRIPTION:
		query_prefix = "subscription "
	else:
		assert("GraphQL method must be one of: query, muration or subscription")
				
	var body = {
		"query": query_prefix + operation_name + " " + query,
		"variables": null,
		"operationName": operation_name
	}
	
	if authenticated:
		return await _auth.make_authenticated_http_post(_endpoint, headers, body)
	else:
		return await _client.make_http_post(_endpoint, headers, body)

func _init(client: AWSAmplifyClient, auth: AWSAmplifyAuth, config: Dictionary) -> void:
	_client = client
	_auth = auth
	_config = config
	_endpoint = _config[CONFIG.URL]

extends Node

@export var mob_scene: PackedScene

@onready var score_label: Label = %ScoreLabel
@onready var leaderboard: ItemList = %Leaderboard

func _ready():
	$UserInterface/Retry.hide()

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
		# warning-ignore:return_value_discarded
		get_tree().reload_current_scene()


func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on the SpawnPath.
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	mob_spawn_location.progress_ratio = randf()

	# Communicate the spawn location and the player's location to the mob.
	var player_position = $Player.position
	mob.initialize(mob_spawn_location.position, player_position)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)
	# We connect the mob to the score label to update the score upon squashing a mob.
	mob.squashed.connect($UserInterface/ScoreLabel._on_Mob_squashed)


func _on_player_hit():
	$MobTimer.stop()
	$UserInterface/Retry.show()
	await _update_player_score()
	await _refresh_leaderboard()

func _update_player_score():	
	var current_score = int(score_label.score)
	var username = await aws_amplify.auth.get_user_attribute(AWSAmplify.USER_ATTRIBUTES.EMAIL)
	var get_score_response = await aws_amplify.data.make_graphql_query("""getScore(leaderboard: "%s", username: "%s") { score }""" % ["global", username], "GetScore")

	if get_score_response.success:
		if get_score_response.response_body.data.getScore == null:
			await aws_amplify.data.make_graphql_mutation("""createScore(input: {leaderboard: "%s", score: %s, username: "%s"}) { createdAt }""" % ["global", str(current_score), username], "CreateScore")
		elif int(get_score_response.response_body.data.getScore.score) < current_score:
			await aws_amplify.data.make_graphql_mutation("""updateScore(input: {leaderboard: "%s", score: %s, username: "%s"}) { createdAt }""" % ["global", str(current_score), username], "UpdateScore")
	else:
		print("Error: " + get_score_response.message)
		
func _refresh_leaderboard():
	var request = """listScoreByLeaderboardAndScore(leaderboard: "%s", sortDirection: DESC, limit:%s) { items { score username } }""" % ["global", "30"]
	var response = await aws_amplify.data.make_graphql_query(request)
	var json = response.response_body

	if json.has("data"):
		var items = json.data.listScoreByLeaderboardAndScore.items
		leaderboard.clear()
		for i in items.size():
			var item = items[i]
			leaderboard.add_item("%s | %s %s" % [str(i+1), item.username, item.score])

func _on_button_pressed() -> void:
	aws_amplify.auth.global_sign_out()

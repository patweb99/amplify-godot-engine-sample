extends Node

@export var mob_scene: PackedScene


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


func _on_music_player_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		MusicPlayer.play()
	else:
		MusicPlayer.stop()


func _on_button_pressed() -> void:
	aws_amplify.auth.global_sign_out()

func _on_user_attributes_button_pressed(toggled) -> void:
	if toggled:
		$MobTimer.stop()
		$UserInterface/UserAttributes.visible = true
	else:
		_on_update_pressed()

func _on_update_pressed() -> void:
	$MobTimer.start()
	$UserInterface/UserAttributes.visible = false

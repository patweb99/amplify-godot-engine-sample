extends Node

@onready var auth_form: AuthForm = %AuthForm
@onready var retry: ColorRect = %Retry

@export var mob_scene: PackedScene

func _ready():
	auth_form.show()
	retry.hide()
	
	aws_amplify.auth.user_signed_in.connect(_on_user_signed_in)
	aws_amplify.auth.user_signed_out.connect(_on_user_signed_out)
	
func _on_user_signed_in(user):
	print("signed-in", user)
	auth_form.hide()
	retry.show()

func _on_user_signed_out(user):
	print("signed-out", user)
	auth_form.show()
	retry.hide()
	
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
	%Retry.show()

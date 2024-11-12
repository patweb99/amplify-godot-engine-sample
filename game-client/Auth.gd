extends Node

const AUTH_FORM = preload("res://addons/aws-amplify/runtime/ui/auth_form.tscn")
const MAIN = preload("res://Main.tscn")

var auth_form: AuthForm
var main: Node

func _ready() -> void:
	if aws_amplify.auth.is_user_signed_in():
		main = MAIN.instantiate()
		add_child(main)
	else:
		auth_form = AUTH_FORM.instantiate()
		add_child(auth_form)
	
func _enter_tree() -> void:
	aws_amplify.auth.user_signed_in.connect(_user_signed_in)
	aws_amplify.auth.user_signed_out.connect(_user_signed_out)

func _exit_tree() -> void:
	aws_amplify.auth.user_signed_in.disconnect(_user_signed_in)
	aws_amplify.auth.user_signed_out.disconnect(_user_signed_out)

func _user_signed_in(_user_attributes) -> void:
	remove_child(auth_form)
	auth_form.queue_free()
	
	main = MAIN.instantiate()
	add_child(main)

func _user_signed_out(_user_attributes) -> void:
	auth_form = AUTH_FORM.instantiate()
	add_child(auth_form)
	
	remove_child(main)
	main.queue_free()

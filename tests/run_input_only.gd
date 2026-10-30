extends SceneTree

const InputRouterTests = preload("res://tests/test_input_router.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var errors := await InputRouterTests.run(self)
	for error in errors:
		push_error(error)
	quit(0 if errors.is_empty() else 1)

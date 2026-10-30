class_name GameSessionConfig
extends RefCounted

enum GameMode {
	SINGLE_PLAYER,
	LOCAL_COOP,
}

enum SinglePlayerControl {
	MOUSE,
	KEYBOARD,
}

var game_mode: GameMode = GameMode.SINGLE_PLAYER
var single_player_control: SinglePlayerControl = SinglePlayerControl.MOUSE


func get_active_player_ids() -> Array[int]:
	var result: Array[int] = [1]
	if game_mode == GameMode.LOCAL_COOP:
		result.append(2)
	return result


func is_single_player() -> bool:
	return game_mode == GameMode.SINGLE_PLAYER


func uses_mouse(player_id: int) -> bool:
	return is_single_player() and player_id == 1 and single_player_control == SinglePlayerControl.MOUSE


func duplicate_config() -> GameSessionConfig:
	var result := GameSessionConfig.new()
	result.game_mode = game_mode
	result.single_player_control = single_player_control
	return result


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if game_mode != GameMode.SINGLE_PLAYER and game_mode != GameMode.LOCAL_COOP:
		errors.append("game_mode 不是合法的游戏模式")
	if single_player_control != SinglePlayerControl.MOUSE and single_player_control != SinglePlayerControl.KEYBOARD:
		errors.append("single_player_control 不是合法的单人操作方式")
	return errors

extends Overlays
class_name ChatOverlay

@onready var message: LineEdit = %Message as LineEdit
@onready var send: Button = %Send
@onready var players_list: ItemList = %PlayersList
@onready var chat_messages: RichTextLabel = %ChatMessages

func _ready():
	chat_messages.clear()
	GameState.OnChatMessageAdded.connect(
		func(chat_message: ChatMessage):
			chat_messages.add_text(chat_message.sender_name + ": "+chat_message.message)
			chat_messages.newline()			
	)
	
func sync_with_game_state():
	players_list.clear()
	
	for player_info in GameState.all_players_info:
		if player_info is PlayerInfo:
			players_list.add_item(player_info.character_name)

func _process(delta):
	pass

func _on_send_pressed():
	GameState.add_chat_message.rpc(GameState.my_player.character.character_name, message.text)
	message.clear()
	message.release_focus()
	GameState.start_my_player_process()

func _on_message_text_submitted(new_text):
	_on_send_pressed() 

func _on_message_text_changed(new_text):
	GameState.stop_my_player_process()

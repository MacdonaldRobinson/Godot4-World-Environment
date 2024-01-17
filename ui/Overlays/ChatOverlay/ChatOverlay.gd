extends Overlays
class_name ChatOverlay

@onready var message: LineEdit = %Message as LineEdit
@onready var send: Button = %Send
@onready var players_list: ItemList = %PlayersList
@onready var chat_messages: RichTextLabel = %ChatMessages

var player: Player
# Called when the node enters the scene tree for the first time.
func _ready():
	chat_messages.clear()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	pass
	
func set_players(players: Array[Node], my_player: Player):
	self.player = my_player
	
	players_list.clear()
	
	for player in players:
		if player is Player:
			var character: Character = player.character as Character
			
			if character:
				players_list.add_item(character.character_name)
			

@rpc("call_local", "any_peer")
func send_message(message: String):
	chat_messages.add_text(message)
	chat_messages.newline()

func _on_send_pressed():
	send_message.rpc(GameState.my_player.character.character_name+": "+message.text)
	message.clear()
	message.release_focus()
	GameState.start_my_player_process()

func _on_message_text_submitted(new_text):
	_on_send_pressed() 

func _on_message_text_changed(new_text):
	GameState.stop_my_player_process()

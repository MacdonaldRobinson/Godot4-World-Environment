extends Node

var is_server := false
var peer: ENetMultiplayerPeer = null

func start_network(server: bool, ip: String = '127.0.0.1', port: int = 4242) -> void:
	is_server = server
	var my_player_info: PlayerInfo = GameState.get_my_player_info()	
	
	peer = ENetMultiplayerPeer.new()

	if server:
		peer.create_server(port)
		
		my_player_info.peer_id = multiplayer.get_unique_id()
		
		GameState.all_players_info.clear()
		GameState._add_or_update_player_info(my_player_info)
		
		multiplayer.peer_connected.connect(_on_peer_connected)		
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
	else:
		peer.create_client(ip, port)		
			
		multiplayer.connected_to_server.connect(_on_connected_to_server)

	multiplayer.set_multiplayer_peer(peer)
	
func _on_peer_connected(peer_id:int):				
	for existing_player_info in GameState.all_players_info:
		if existing_player_info is PlayerInfo:
			if existing_player_info.peer_id != peer_id:
				# Add existing peers to new peer
				GameState.add_or_update_player_info.rpc_id(peer_id, var_to_str(existing_player_info))
				pass

func _on_peer_disconnected(peer_id:int):
	GameState.remove_player.rpc(peer_id)
	
func _on_connected_to_server():
	# Add my player to all peers
	# Seems to only call the server, so had to send to existing players from the add_player from the server				

	var my_player_info: PlayerInfo = GameState.get_my_player_info()	
	my_player_info.peer_id = multiplayer.get_unique_id()
					
	GameState.all_players_info.clear()
	GameState.add_or_update_player_info.rpc(var_to_str(my_player_info))	

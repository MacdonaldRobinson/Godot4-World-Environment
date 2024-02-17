extends Node

var is_server := false

func start_network(server: bool, ip: String = '127.0.0.1', port: int = 4242) -> void:
	is_server = server
	var peer = ENetMultiplayerPeer.new()
	
	var my_player_info: PlayerInfo = PlayerInfo.new()
	my_player_info.character_scene_file_path = GameState.my_player.character.scene_file_path
	my_player_info.character_name = GameState.my_player.character.character_name		
	my_player_info.health = 100
	my_player_info.is_in_game = false
	my_player_info.character_photo = GameState.my_player.character.character_photo
	
	if server:
		peer.create_server(port)		

		my_player_info.peer_id = multiplayer.get_unique_id()
		GameState._add_or_update_player_info(my_player_info)	
				
		multiplayer.peer_connected.connect(
			func(peer_id:int):				
				for existing_player_info in GameState.all_players_info:
					if existing_player_info is PlayerInfo:
						if existing_player_info.peer_id != peer_id:
							# Add existing peers to new peer
							GameState.add_or_update_player_info.rpc_id(peer_id, var_to_str(existing_player_info))
							pass
		)
		
		multiplayer.peer_disconnected.connect(
			func(peer_id: int):
				GameState.remove_player.rpc(peer_id)
		)
	else:
		peer.create_client(ip, port)		
				
		multiplayer.connected_to_server.connect(
			func():
				# Add my player to all peers
				# Seems to only call the server, so had to send to existing players from the add_player from the server				
				my_player_info.peer_id = multiplayer.get_unique_id()	
				GameState.add_or_update_player_info.rpc(var_to_str(my_player_info))
		)

	multiplayer.set_multiplayer_peer(peer)

extends Node

var is_server := false

func start_network(server: bool, ip: String = '127.0.0.1', port: int = 4242) -> void:
	is_server = server
	var peer = ENetMultiplayerPeer.new()
	if server:
		peer.create_server(port)
		GameState.add_player(multiplayer.get_unique_id(), GameState.my_player.character.scene_file_path, GameState.my_player.character.character_name)
		multiplayer.peer_connected.connect(
			func(peer_id:int): 
				for player in GameState.players_container.get_children():
					if player is Player:
						if player.name != str(peer_id):
							# Add existing peers to new peer
							GameState.add_player.rpc_id(peer_id, player.name.to_int(), player.character.scene_file_path, player.character.character_name)
		)
		
		multiplayer.peer_disconnected.connect(
			func(peer_id: int):
				if self:
					GameState.remove_player.rpc(peer_id)
		)
	else:
		peer.create_client(ip, port)

		multiplayer.connected_to_server.connect(
			func():
				# Add my player to all peers
				# Seems to only call the server, so had to send to existing players from the add_player from the server
				GameState.add_player.rpc(multiplayer.get_unique_id(), GameState.my_player.character.scene_file_path, GameState.my_player.character.character_name)
		)

	multiplayer.set_multiplayer_peer(peer)

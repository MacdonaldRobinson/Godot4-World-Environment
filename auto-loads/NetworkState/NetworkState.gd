extends Node

var is_server = false
var peer: ENetMultiplayerPeer = null
var upnp: UPNP = null
var port: int = 5120

func create_server():
	is_server = true
	var my_player_info: PlayerInfo = GameState.get_my_player_info()		
	peer = ENetMultiplayerPeer.new()
	
	peer.create_server(port)
	
	my_player_info.peer_id = multiplayer.get_unique_id()
	
	GameState.all_players_info.clear()
	GameState._add_or_update_player_info(my_player_info)
	
	multiplayer.peer_connected.connect(_on_peer_connected)		
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	multiplayer.set_multiplayer_peer(peer)
	
	return upup_setup(port)
	
func create_client(ip: String):
	var my_player_info: PlayerInfo = GameState.get_my_player_info()		
	peer = ENetMultiplayerPeer.new()
		
	peer.create_client(ip, port)	
	
	multiplayer.set_multiplayer_peer(peer)
	
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)	
	
	
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

func upup_setup(port) -> String:
	upnp = UPNP.new()	
	var dicover_resuilt = upnp.discover()
	
	assert(dicover_resuilt == UPNP.UPNP_RESULT_SUCCESS, "Error")
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "Error")
	
	var map_result = upnp.add_port_mapping(port)
	
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "Error")
	
	return upnp.query_external_address()
		
		
	
	

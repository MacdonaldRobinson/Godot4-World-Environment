extends Node

var is_server := false

func start_network(server: bool, ip: String = '127.0.0.1', port: int = 4242) -> void:
	is_server = server
	var peer = ENetMultiplayerPeer.new()
	if server:
		peer.create_server(port)		
	else:
		peer.create_client(ip, port)
		multiplayer.connection_failed.connect(
			func():
				print("connection failed")
		)
		multiplayer.connected_to_server.connect(
			func():
				print("connection successful")
		)

	multiplayer.set_multiplayer_peer(peer)

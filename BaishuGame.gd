extends Node2D

const pieces := [
	[Color("#af0e0e"), preload("res://fire.png"), preload("res://ofire.png")], # fire
	[Color("#ffffe3"), preload("res://order.png"), preload("res://oorder.png")], # order
	[Color("#1c1c1c"), preload("res://chaos.png"), preload("res://ochaos.png")], # chaos
	[Color("#ffdb5e"), preload("res://air.png"), preload("res://oair.png")], # air
	[Color("#84d6ff"), preload("res://water.png"), preload("res://owater.png")], #water
	[Color("#37b830"), preload("res://earth.png"), preload("res://oearth.png")], #earth
]

const killers := [
	[5,4],
	[0,3],
	[0,1],
	[2,5],
	[2,3],
	[4,1],
]
const killeds := [
	[1, 2],
	[2, 5],
	[3, 4],
	[1, 4],
	[0, 5],
	[0, 3],
]


var amounts := {
	true: [12, 12, 12, 12, 12, 12],
	false: [12, 12, 12, 12, 12, 12],
}


var map := {}

var colors = ["#fe72c1", "#c05594", "#d35fa1", "#af4d87"]

var mouse_position := Vector2(0, 0)

var new_pieces := {}

var piece_to_add := 0
remote var side := false

var movadds := 2
var deletes := 1


var to_move = null

remote var game_connection := -1
remote var this_side := false

var first_turn := true


func _ready() -> void:
	var peer := NetworkedMultiplayerENet.new()
	peer.create_client("server_ip_here_i_guess", 6969)
	get_tree().network_peer = peer
	$Board.position = get_viewport_rect().size / 2.0 * Vector2(0.5,1.0)
	
	for q in range(-Consts.board_size, Consts.board_size + 1):
		for r in range(-Consts.board_size, Consts.board_size + 1):
			if Hex.dist_from_center(q, r) <= Consts.board_size:
				var n_hex := Hex.new()
				n_hex.q = q
				n_hex.r = r
				n_hex.color = colors[(-q+r) % 3]
				map[Vector2(q, r)] = n_hex
				$Board.add_child(n_hex)
	update()


func _process(delta: float) -> void:
	update()
	if game_connection != -1:
		$Label.text = "connected to someone!"
	
	$Label2.text = ""
	var ells := ["Fire", "Order", "Chaos", "Air", "Water", "Earth"]
	for i in 6:
		$Label2.text += ells[i] + "\n" + str(amounts[this_side][i]) + " - "
		$Label2.text += str(amounts[!this_side][i]) + "\n\n"

func _input(event: InputEvent) -> void:
	if !first_turn and movadds >= 2:
		movadds = 1
	if game_connection != -1:
		print(side, " ", this_side)
	var p = Hex.pixel_to_hex(get_global_mouse_position() - $Board.position)
	if Hex.dist_from_center(p.x, p.y) <= Consts.board_size:
		mouse_position = p
	
	if side == this_side and game_connection != -1:
		if Input.is_action_just_pressed("click"):
			if movadds > 0:
				if map[mouse_position].element == -1 and not mouse_position in new_pieces:
					if to_move == null:
						new_pieces[mouse_position] = [piece_to_add, side]
						movadds -= 1
					else:
						if Hex.dist(mouse_position, to_move) <= movadds:
							movadds -= Hex.dist(mouse_position, to_move)
							map[mouse_position].element = map[to_move].element
							map[to_move].element = -1
							to_move = null
				elif map[mouse_position].element != -1 and not mouse_position in new_pieces:
					if to_move == null and map[mouse_position].side == side:
						to_move = mouse_position
					elif to_move == mouse_position:
						to_move = null
		
		elif Input.is_action_just_pressed("rclick"):
			if mouse_position in new_pieces:
				new_pieces.erase(mouse_position)
				movadds += 1
			elif map[mouse_position].side == side and map[mouse_position].element != -1 and deletes > 0:
				new_pieces[mouse_position] = [-1, side]
				deletes -= 1
			
		elif Input.is_action_just_pressed("scroll_up"):
			piece_to_add = abs((piece_to_add + 1) % 6)
			
		elif Input.is_action_just_pressed("scroll_down"):
			piece_to_add -= 1
			if piece_to_add < 0:
				piece_to_add = 5
			
		elif Input.is_action_just_pressed("swap"):
			first_turn = false
			for c in new_pieces.duplicate():
				map[c].element = new_pieces[c][0]
				map[c].side = new_pieces[c][1]
				rpc_id(1, "add_to_amount", map[c].side, map[c].element, -1, game_connection)
				new_pieces.erase(c)
			
			for c in map.duplicate():
				if not map[c].element == -1:
					var counter := 0
					var counter_k := 0
					for n in [Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, -1), Vector2(0, -1), Vector2(0, 1)]:
						var cn :Vector2 = c + n
						if cn in map.duplicate():
							if map[cn].element != -1:
								if map[cn].element in killers[map[c].element]:
									counter += 1
									if counter >= 2:
										rpc_id(1, "add_to_amount", !map[c].side, map[c].element, 1, game_connection)
										map[c].element = -1
										break
								if map[cn].element in killeds[map[c].element]:
									counter_k += 1
									if counter_k >= 2:
										map[c].element = -1
										break
			side = not this_side
			movadds = 2
			deletes = 1
			encode_map()
			rpc_id(1, "swap", game_connection, encode_map())
	update()
	
	for i in $List.get_child_count():
		var child = $List.get_child(i)
		child.get_node("HexagonCount").color = pieces[i][0]
		child.get_node("Sprite").texture = pieces[i][1]
		child.get_node("Sprite").modulate = Color("#ffffff")
		if i == 1:
			child.get_node("Sprite").modulate = Color("#000000")
		child.scale = Vector2.ONE
		if i == piece_to_add:
			child.scale = Vector2.ONE * 1.3

func _draw() -> void:
	for c in map:
		var cell :Hex = map[c]
		var cellement = cell.element
		var cellside = cell.side
		var lighten := false
		if c in new_pieces:
			cellement = new_pieces[c][0]
			cellside = new_pieces[c][1]
			lighten = true
		match cellement:
			-1:
				cell.color = colors[(-c.x+c.y) as int % 3]
				if c == mouse_position:
					cell.color = cell.color.linear_interpolate(pieces[piece_to_add][0], 0.5).lightened(0.4)
			var ell:
				if not lighten:
					cell.color = pieces[ell][0]
				else:
					cell.color = colors[(-c.x+c.y) as int % 3]
					cell.color = cell.color.linear_interpolate(pieces[ell][0], 0.5)
				if c == mouse_position:
					cell.color = cell.color.lightened(0.55)
				var t_modulate := Color("#ffffff")
				if cellement == 1:
					t_modulate = Color("000000")
				if cellside == this_side:
					draw_texture(pieces[ell][1], $Board.position + cell.position - Vector2(14.5, 16), t_modulate)
				else:
					draw_texture(pieces[ell][2], $Board.position + cell.position - Vector2(14.5, 16), t_modulate)


func modi(number:int, mod:int) -> int:
	if number >= mod:
		return number % mod
	elif number > 0:
		return number
	else:
		var n := number
		while n < 0:
			n = mod + n
		return n


remote func get_swap(info) -> void:
	decode_map(info)
	movadds = 2
	deletes = 1
	update()


func encode_map() -> String:
	var ret := ""
	for i in map:
		ret += "%s, %s;" % [i.x, i.y]
		ret += str(map[i].element) + ";"
		if map[i].side:
			ret += "tru&"
		else:
			ret += "&"
	ret = ret.rstrip("&")
	return ret


func decode_map(ma:String):
	var r = ma.split("&")
	for i in r:
		var s :Array = i.split(";")
		var vt :Array = s[0].split(", ")
		var v = Vector2(vt[0], vt[1])
		map[v].element = int(s[1])
		map[v].side = bool(s[2])


remote func add_to_amount(side, piece, amt):
	amounts[side][piece] += amt

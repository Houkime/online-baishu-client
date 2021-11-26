extends Polygon2D

class_name Hex


var q := 0.0 setget set_q
var r := 0.0 setget set_r

var element := -1
var side := false

func _ready() -> void:
	var poly := []
	for i in 6.0:
		poly.append(Vector2(Consts.hex_size,0.0).rotated(i*TAU/6.0))
	polygon = poly


func set_q(value):
	position.x = Consts.hex_size * (3/2.0 * value)
	position.y = Consts.hex_size * (sqrt(3)/2.0 * value  +  sqrt(3) * r)
	q = value

func set_r(value):
	position.x = Consts.hex_size * (3/2.0 * q)
	position.y = Consts.hex_size * (sqrt(3)/2.0 * q  +  sqrt(3) * value)
	r = value


static func pixel_to_hex(p:Vector2) -> Vector2:
	var qr := [0, 0]
	qr[0] = (2/3.0 * p.x) / Consts.hex_size
	qr[1] = (-1/3.0 * p.x + sqrt(3)/3.0 * p.y) / Consts.hex_size
	qr = cube_round(qr[0], qr[1], -qr[0] - qr[1])
	qr.remove(2)
	return Vector2(qr[0], qr[1])


static func cube_round(fq, fr, fs):
	var q = round(fq)
	var r = round(fr)
	var s = round(fs)

	var q_diff = abs(q - fq)
	var r_diff = abs(r - fr)
	var s_diff = abs(s - fs)

	if q_diff > r_diff and q_diff > s_diff:
		q = -r-s
	elif r_diff > s_diff:
		r = -q-s
	else:
		s = -q-r

	return [q, r, s]


static func dist_from_center(fq, fr):
	return max(max(abs(fq), abs(fr)), abs(-fq - fr))


static func dist(a:Vector2, b:Vector2):
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y)+ abs(a.y - b.y)) / 2

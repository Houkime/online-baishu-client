extends Resource

class_name Hex3

var q := 0.0 setget set_q
var r := 0.0 setget set_r
var s := 0.0


func _init(q:float, r:float) -> void:
	q = q
	r = r


func set_q(value:float):
	s = -value - r
	q = value
func set_r(value:float):
	s = -q - value
	r = value

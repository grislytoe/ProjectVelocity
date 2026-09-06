class_name InputFrame
extends RefCounted
## Intent only. No grounded state, abilities, timers, player identity or network calls.

var movement: Vector2 = Vector2.ZERO
var dash_direction: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var jump_held: bool = false
var jump_released: bool = false
var dash_pressed: bool = false
var pause_pressed: bool = false
var restart_held: bool = false

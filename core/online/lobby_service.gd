class_name LobbyService
extends RefCounted
## Non-live operation coordinator. Commands go to a future reviewed EOSG boundary.
## Test commands are not evidence of EOS permissions/search visibility or atomic joining.

enum State { IDLE, CREATING, SEARCHING, JOINING, JOINED, FAILED }
var state: State = State.IDLE
var error_key: String = ""
var code: String = ""
var generation: int = 0
var _deadline_ms: int = 0
var _expected: Dictionary = {}
var _handle: String = "" # Opaque test/service handle; never rendered or logged.

func begin_create(value: Dictionary, now_ms: int) -> int:
	if state != State.IDLE or not _valid_expected(value):
		return -1
	_start(State.CREATING, value, now_ms)
	return generation

func begin_search(value: Dictionary, now_ms: int) -> int:
	if state != State.IDLE or not _valid_expected(value):
		return -1
	_start(State.SEARCHING, value, now_ms)
	return generation

func search_result(epoch: int, rows: Array, complete: bool = true) -> String:
	if epoch != generation or state != State.SEARCHING:
		return ""
	var selection: Dictionary = LobbyPolicy.select(rows, _expected, complete)
	if not selection.error.is_empty():
		_fail(selection.error)
		return ""
	_handle = selection.row.handle
	state = State.JOINING
	return _handle

func admission_result(epoch: int, handle: String, value: Dictionary, members: int,
		owner_present: bool, capacity: int, published: bool) -> bool:
	if epoch != generation or state not in [State.CREATING, State.JOINING]:
		return false # Boundary must leave/destroy any late successful resource itself.
	var expected_members: int = 1 if state == State.CREATING else 2
	if handle.is_empty() or (state == State.JOINING and handle != _handle) or \
		members != expected_members or capacity != 2 or not owner_present or not published or \
		not LobbyPolicy.compatible(value, _expected):
		_fail("EOS_JOIN_FAILED")
		return false # Includes capacity races; boundary must leave rejected admission.
	_handle = handle
	code = _expected.code
	state = State.JOINED
	return true

func membership_changed(owner_present: bool, members: int) -> bool:
	if state != State.JOINED:
		return false
	# No promotion or bearer-only resume. Membership loss closes this composition.
	if not owner_present or members < 1 or members > 2:
		leave()
		return false
	return true

func poll(now_ms: int) -> void:
	if state in [State.CREATING, State.SEARCHING, State.JOINING] and now_ms >= _deadline_ms:
		_fail("EOS_TIMEOUT")

func leave() -> void:
	generation += 1
	state = State.IDLE
	code = ""
	_handle = ""
	_expected.clear()
	error_key = ""

func _start(next: State, value: Dictionary, now_ms: int) -> void:
	generation += 1
	state = next
	_expected = value.duplicate(true)
	_deadline_ms = now_ms + 15000
	error_key = ""

func _valid_expected(value: Dictionary) -> bool:
	return value.get("code") is String and not JoinCode.normalize(value.code).is_empty() and \
		JoinCode.normalize(value.code) == value.code and LobbyPolicy.compatible(value, value)

func _fail(key: String) -> void:
	generation += 1
	state = State.FAILED
	error_key = key
	code = ""
	_handle = ""
	_expected.clear()

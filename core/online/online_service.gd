class_name OnlineService
extends RefCounted
## Non-live lifecycle policy. Native ownership remains blocked; no fake login in production.
## Boundary callbacks supply booleans only; actual credentials/identities never enter UI state.

enum State { OFFLINE, AUTH, CONNECT, ONLINE, LINK_REQUIRED, FAILED, STOPPED }
var state: State = State.OFFLINE
var generation: int = 0
var error_key: String = ""
var _deadline_ms: int = 0

func begin(opt_in: bool, configuration_valid: bool, boundary_available: bool, now_ms: int) -> int:
	if state != State.OFFLINE:
		return -1
	if not opt_in or not configuration_valid or not boundary_available:
		error_key = EOSCapability.unavailable_key()
		return -1
	generation += 1
	state = State.AUTH
	_deadline_ms = now_ms + 30000
	error_key = ""
	return generation

func auth_result(epoch: int, success: bool, account_present: bool, continuance: bool) -> void:
	if epoch != generation or state != State.AUTH:
		return
	if continuance:
		state = State.LINK_REQUIRED
		error_key = "EOS_LINK_REQUIRED"
	elif success and account_present:
		state = State.CONNECT
	else:
		_fail("EOS_AUTH_FAILED")

func connect_result(epoch: int, success: bool, puid_present: bool, continuance: bool) -> void:
	if epoch != generation or state != State.CONNECT:
		return
	if continuance:
		state = State.LINK_REQUIRED
		error_key = "EOS_LINK_REQUIRED"
	elif success and puid_present:
		state = State.ONLINE
	else:
		_fail("EOS_AUTH_FAILED")

func poll(now_ms: int) -> void:
	if state in [State.AUTH, State.CONNECT] and now_ms >= _deadline_ms:
		_fail("EOS_TIMEOUT")

func logout(cleanup: Callable = Callable()) -> void:
	# Invalidate callbacks BEFORE downstream Lobby/P2P cleanup; global SDK stays owned.
	generation += 1
	state = State.OFFLINE if state != State.STOPPED else State.STOPPED
	_deadline_ms = 0
	error_key = ""
	if cleanup.is_valid():
		cleanup.call()

func shutdown(cleanup: Callable = Callable()) -> void:
	if state == State.STOPPED:
		return
	logout(cleanup)
	state = State.STOPPED # SDK shutdown is terminal for this process (M18 observation).

func _fail(key: String) -> void:
	state = State.FAILED
	error_key = key

class_name LobbyClient
extends RefCounted
## AppUI's narrow service port. Default production adapter is explicitly unavailable.
## A future executor owns native cleanup even for cancelled/late successful operations.
## Every operation and subscription uses generation; joined updates use host revision.

signal changed
enum Phase { ENTRY, CREATING, SEARCHING, JOINING, LOBBY, FAILED }
const ERRORS: Array[String] = ["EOS_UNAVAILABLE", "LOB_INVALID_CODE", "EOS_NOT_FOUND",
	"LOB_FULL", "EOS_TIMEOUT", "LOB_CANCELLED", "LOB_DISCONNECTED", "LOB_HOST_LEFT",
	"LOB_PROTOCOL", "LOB_BUILD", "LOB_MAP", "LOB_CHECKSUM", "LOB_REJECTED", "LOB_FAILURE"]
var phase: Phase = Phase.ENTRY
var error_key: String = ""
var generation: int = 0
var pending: bool = false
var request_id: int = 0
var maps: Array[MapDefinition] = MapCatalog.official().filter(
	func(map: MapDefinition) -> bool: return map != null)
var _view: LobbyView
var _deadline: int = 0
var _operation: String = ""

func available() -> bool:
	return false

func view() -> LobbyView:
	return _view.copy() if _view != null else null

func create_lobby(nickname: String) -> void:
	_begin("create", "", nickname)

func join_lobby(code: String, nickname: String) -> void:
	if pending or phase == Phase.LOBBY:
		reject()
		return
	var canonical: String = JoinCode.normalize(code)
	if canonical.is_empty():
		fail(generation, "LOB_INVALID_CODE")
		return
	_begin("join", canonical, nickname)

func _begin(operation: String, code: String, nickname: String) -> void:
	if pending or phase == Phase.LOBBY:
		return
	leave()
	if not available():
		fail(generation, "EOS_UNAVAILABLE")
		return
	if not PlayerProfileData.valid_nickname(nickname):
		fail(generation, "LOB_REJECTED")
		return
	phase = Phase.CREATING if operation == "create" else Phase.SEARCHING
	_arm(operation)
	changed.emit()
	_dispatch(operation, generation, -1, {"code": code, "nickname": nickname})

func searching_complete(epoch: int) -> void:
	if epoch == generation and phase == Phase.SEARCHING and pending:
		phase = Phase.JOINING
		changed.emit()

func receive(epoch: int, snapshot: LobbyView, acknowledgement: int = -1) -> void:
	if epoch != generation or phase not in [Phase.CREATING, Phase.JOINING, Phase.LOBBY]:
		return
	if snapshot == null or not snapshot.valid(maps):
		fail(epoch, "LOB_FAILURE")
		return
	if _view != null and snapshot.revision <= _view.revision:
		# A publication notification can beat the operation acknowledgement. Unlock
		# the matching request without replacing newer authoritative presentation.
		if pending and acknowledgement == request_id:
			pending = false
			error_key = ""
			changed.emit()
		return
	_view = snapshot.copy()
	if phase != Phase.LOBBY or acknowledgement == request_id:
		pending = false
	phase = Phase.LOBBY
	error_key = ""
	changed.emit()

func can_start() -> bool:
	return phase == Phase.LOBBY and not pending and _view != null and \
		_view.local_host and _view.guest_connected and _view.guest_ready and not _view.starting

func change_settings(settings: MatchSettings) -> void:
	if not _may_request() or not _view.local_host or settings == null or not settings.valid(maps):
		reject()
		return
	_request("settings", {"settings": settings.copy()})

func set_ready(value: bool) -> void:
	if not _may_request() or _view.local_host or not _view.guest_connected:
		reject()
		return
	_request("ready", {"ready": value})

func start_match() -> void:
	if not can_start():
		reject()
		return
	_request("start", {})

func _may_request() -> bool:
	return phase == Phase.LOBBY and not pending and _view != null and not _view.starting

func _request(operation: String, payload: Dictionary) -> void:
	_arm(operation)
	error_key = ""
	changed.emit() # Start is disabled before dispatch; no optimistic readiness/settings.
	_dispatch(operation, generation, _view.revision, payload)

func _arm(operation: String) -> void:
	request_id += 1
	pending = true
	_operation = operation
	_deadline = Time.get_ticks_msec() + 15000

func poll(now_ms: int) -> void:
	if pending and now_ms >= _deadline:
		fail(generation, "EOS_TIMEOUT")

func reject() -> void:
	error_key = "LOB_REJECTED"
	changed.emit()

func operation_failed(epoch: int, request: int, key: String) -> void:
	# Operation callbacks must include BOTH tokens; terminal membership loss uses fail().
	if epoch == generation and request == request_id and pending:
		fail(epoch, key)

func fail(epoch: int, key: String) -> void:
	if epoch != generation:
		return
	leave()
	phase = Phase.FAILED
	error_key = key if key in ERRORS else "LOB_FAILURE"
	changed.emit()

func cancel() -> void:
	fail(generation, "LOB_CANCELLED")

func leave() -> void:
	var old_epoch: int = generation
	generation += 1
	_cleanup(old_epoch)
	phase = Phase.ENTRY
	_view = null
	pending = false
	_operation = ""
	error_key = ""

func _dispatch(_command: String, epoch: int, _revision: int, _payload: Dictionary) -> void:
	fail(epoch, "EOS_UNAVAILABLE")

func _cleanup(_epoch: int) -> void:
	pass

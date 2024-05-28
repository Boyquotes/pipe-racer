extends Area3D
class_name Checkpoint

# var collectedMaterial := preload("res://Track Props/CheckPointGreen.tres")
# var uncollectedMaterial := preload("res://Track Props/CheckPointRed.tres")


signal bodyEnteredCheckpoint(body: Node3D, checkpoint: Node3D)

var index: int = -1

@onready var checkpointModel: Node3D = %ProceduralCheckpoint

func _ready():
	body_entered.connect(onBodyEntered)
	
	setUncollected()

func onBodyEntered(body):
	print("[Checkpoint.gd] Body entered checkpoint: ", body)
	bodyEnteredCheckpoint.emit(body, self)

var placements: Array = []

func getPlacement(lapNumber: int) -> int:
	if placements.size() <= lapNumber:
		placements.push_back(0)
	
	placements[lapNumber] += 1
	return placements[lapNumber]

func isCheckPoint():
	pass

const RAYCAST_MAX_DISTANCE = 140

var raycastPosition = null
var raycastNormal = null

# 10 units back
# 24 units sideways

func getRespawnPosition(playerIndex: int, nrPlayers: int) -> Dictionary:
	var localBackwards = -global_transform.basis.z

	var localRight = -global_transform.basis.x

	var leftLimit = -localRight * 18.01
	var rightLimit = localRight * 18.02

	var playerFraction = remap(playerIndex, 0, nrPlayers - 1, 0, 1)

	if nrPlayers == 1:
		playerFraction = 0.5

	var raycastOrigin = global_position + (localBackwards.normalized() * 0.001) + Vector3.UP * 24 + leftLimit.lerp(rightLimit, playerFraction)

	calculateRaycast(raycastOrigin)

	var spawnPosition = raycastPosition + raycastNormal * 0.35

	# print("Spawn position: ", spawnPosition)

	return {
		"position": spawnPosition,
		"rotation": getRotationVector(-localBackwards, (-localBackwards).cross(raycastNormal).normalized())
	}

func getRotationVector(localForward: Vector3, localRight: Vector3) -> Vector3:
	var localBasis = Basis(localRight, localForward.cross(localRight).normalized(), -localForward)
	var localQuaternion = Quaternion(localBasis.get_rotation_quaternion())

	print("Rotation: ", localQuaternion.get_euler())

	return localQuaternion.get_euler()

func calculateRaycast(origin: Vector3):
	var spaceState = get_world_3d().direct_space_state

	var to = origin + Vector3.DOWN * RAYCAST_MAX_DISTANCE

	var result = spaceState.intersect_ray(PhysicsRayQueryParameters3D.create(origin, to, 1))

	if result.has("position"):
		raycastPosition = result.position
		raycastNormal = result.normal
	else:
		raycastPosition = null
		raycastNormal = null

func collect():
	setCollected()

func setCollected():
	checkpointModel.setCollected()

func setUncollected():
	checkpointModel.setUncollected()

func reset():
	setUncollected()
	placements.clear()

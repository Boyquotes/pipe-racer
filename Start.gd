extends Node3D
class_name Start

const RAYCAST_MAX_DISTANCE = 100

var raycastPosition = null
var raycastNormal = null

# 10 units back
# 24 units sideways

func isStart():
	pass

func getStartPosition(playerIndex: int, nrPlayers: int) -> Dictionary:
	if raycastPosition == null || raycastNormal == null:
		calculateRaycast()

	var localBackwards = -global_transform.basis.x

	var localRight = (-localBackwards).cross(raycastNormal).normalized()

	var baseSpawnPosition = raycastPosition + raycastNormal * 0.2 + localBackwards * 8

	var leftLimit = -localRight * 24
	var rightLimit = localRight * 24

	var playerFraction = remap(playerIndex, 0, nrPlayers - 1, 0, 1)

	var spawnPosition = baseSpawnPosition + leftLimit.lerp(rightLimit, playerFraction)

	return {
		"position": spawnPosition,
		"rotation": getRotationVector(-localBackwards, localRight)
	}

func getRotationVector(localForward: Vector3, localRight: Vector3) -> Vector3:
	var localBasis = Basis(localForward, localForward.cross(localRight).normalized(), localRight)
	var localQuaternion = Quaternion(localBasis)

	return localQuaternion.get_euler()

func calculateRaycast():
	var spaceState = get_world_3d().direct_space_state

	var from = global_position
	var to = from + Vector3.DOWN * RAYCAST_MAX_DISTANCE

	var result = spaceState.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

	if result.has("position"):
		raycastPosition = result.position
		raycastNormal = result.normal
	else:
		raycastPosition = null
		raycastNormal = null

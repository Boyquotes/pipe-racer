extends Node3D
class_name EditorEventListener

@onready var inputHandler: EditorInputHandler = %EditorInputHandler
@onready var camera: EditorCamera = %EditorCamera
# @onready var previewElementParent: Node3D = %PreviewElement
@onready var map: InteractiveMap = %InteractiveMap

@onready var roadNode: RoadNode = %RoadNode
@onready var pipeNode: PipeNode = %PipeNode
var currentElement: Node3D = null

@onready var editorSidebarUI: EditorSidebarUI = %EditorSidebarUI

@onready var roadNodePropertiesUI: RoadNodePropertiesUI = %RoadNodePropertiesUI
@onready var roadPropertiesUI: RoadPropertiesUI = %RoadPropertiesUI

@onready var pipeNodePropertiesUI: PipeNodePropertiesUI = %PipeNodePropertiesUI
@onready var pipePropertiesUI: PipePropertiesUI = %PipePropertiesUI

@onready var sceneryEditorUI: SceneryEditorUI = %SceneryEditorUI

enum EditorMode {
	BUILD,
	EDIT,
	DELETE,
	SCENERY,
	PAINT,
}

var currentEditorMode: EditorMode = EditorMode.BUILD

enum BuildMode {
	ROAD,
	PIPE,
	START,
	CP,
	DECO
}

var currentBuildMode: BuildMode = BuildMode.ROAD

func _ready():
	setUIVisibility()
	setCurrentElement()

	connectSignals()

func connectSignals():
	inputHandler.mouseMovedTo.connect(func(worldPos: Vector3):
		if worldPos == Vector3.INF:
			return
		
		if currentElement == null:
			return

		currentElement.global_position = worldPos
	)

	inputHandler.moveUpGrid.connect(func():
		camera.global_position += Vector3.UP * PrefabConstants.GRID_SIZE
	)

	inputHandler.moveDownGrid.connect(func():
		camera.global_position += Vector3.DOWN * PrefabConstants.GRID_SIZE
	)

	inputHandler.rotatePressed.connect(func(axis: Vector3, angle: float):
		if currentElement == null:
			return

		if axis == Vector3.UP:
			currentElement.global_rotation.y += angle
		elif axis == Vector3.RIGHT:
			currentElement.global_rotation.x += angle
		elif axis == Vector3.FORWARD:
			currentElement.global_rotation.z += angle
		
		currentElement.global_rotation = currentElement.global_rotation.snapped(Vector3.ONE * deg_to_rad(5))
	)
	inputHandler.resetRotationPressed.connect(func():
		if currentElement == null:
			return

		currentElement.global_rotation = Vector3.ZERO
	)

	inputHandler.placePressed.connect(func():
		if currentEditorMode == EditorMode.SCENERY:
			map.onInputHandler_placePressed()
			return
		
		if currentElement == null:
			return

		if ClassFunctions.getClassName(currentElement) == "RoadNode":
			var collidedObject = screenPointToRay()
			if collidedObject != null: # && map.lastRoadElement == null:
				collidedObject = collidedObject.get_parent()
				print("[EditorEventListener.gd] Class of collidedObject: ", ClassFunctions.getClassName(collidedObject))

				if ClassFunctions.getClassName(collidedObject) == "RoadNode":
					currentElement.global_position = collidedObject.global_position
					currentElement.global_rotation = collidedObject.global_rotation


			var newElement = currentElement.getCopy()
			map.addRoadNode(
				newElement, 
				currentElement.global_position, 
				currentElement.global_rotation,
				roadPropertiesUI.getProperties()
			)
		elif ClassFunctions.getClassName(currentElement) == "PipeNode":
			var collidedObject = screenPointToRay()
			if collidedObject != null:
				collidedObject = collidedObject.get_parent()
				print("[EditorEventListener.gd] Class of collidedObject: ", ClassFunctions.getClassName(collidedObject))

				if ClassFunctions.getClassName(collidedObject) == "PipeNode":
					currentElement.global_position = collidedObject.global_position
					currentElement.global_rotation = collidedObject.global_rotation
				
			var newElement = currentElement.getCopy()
			map.addPipeNode(
				newElement, 
				currentElement.global_position, 
				currentElement.global_rotation,
				pipePropertiesUI.getProperties()
			)


	)

	map.roadPreviewElementRequested.connect(func():
		map.onRoadPreviewElementProvided(roadNode)
	)

	map.pipePreviewElementRequested.connect(func():
		map.onPipePreviewElementProvided(pipeNode)
	)

	# sidebar
	editorSidebarUI.buildModeChanged.connect(func(mode: BuildMode):
		map.clearPreviews()
		currentBuildMode = mode
		setUIVisibility()
		setCurrentElement()
	)

	editorSidebarUI.editorModeChanged.connect(func(mode: EditorMode):
		currentEditorMode = mode
		inputHandler.editorMode = mode
		setUIVisibility()
		setCurrentElement()
	)

	# road node properties ui
	roadNodePropertiesUI.roadProfileChanged.connect(func(profile: int):
		if currentElement == null || ClassFunctions.getClassName(currentElement) != "RoadNode":
			return
		
		currentElement = currentElement as RoadNode
		currentElement.profileType = profile as RoadNode.RoadProfile
	)

	roadNodePropertiesUI.profileHeightChanged.connect(func(value: float):
		if currentElement == null || ClassFunctions.getClassName(currentElement) != "RoadNode":
			return
		
		currentElement = currentElement as RoadNode
		currentElement.profileHeight = value
	)

	roadNodePropertiesUI.widthChanged.connect(func(value: float):
		if currentElement == null || ClassFunctions.getClassName(currentElement) != "RoadNode":
			return
		
		currentElement = currentElement as RoadNode
		currentElement.width = value
	)

	roadNodePropertiesUI.leftRunoffChanged.connect(func(value: float):
		if currentElement == null || ClassFunctions.getClassName(currentElement) != "RoadNode":
			return
		
		currentElement = currentElement as RoadNode
		currentElement.leftRunoff = value
	)

	roadNodePropertiesUI.rightRunoffChanged.connect(func(value: float):
		if currentElement == null || ClassFunctions.getClassName(currentElement) != "RoadNode":
			return
		
		currentElement = currentElement as RoadNode
		currentElement.rightRunoff = value
	)

	# road properties ui
	roadPropertiesUI.roadSurfaceChanged.connect(func(surface: int):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.surfaceType = surface as PhysicsSurface.SurfaceType
	)

	roadPropertiesUI.wallMaterialChanged.connect(func(material: int):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.wallSurfaceType = material as PhysicsSurface.SurfaceType
	)

	roadPropertiesUI.supportTypeChanged.connect(func(type: int):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.supportType = type as RoadMeshGenerator.SupportType
	)

	roadPropertiesUI.supportMaterialChanged.connect(func(material: int):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.supportMaterial = material as PhysicsSurface.SurfaceType
	)

	roadPropertiesUI.supportBottomChanged.connect(func(bottom: float):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.supportBottomHeight = bottom
	)

	roadPropertiesUI.leftWallTypeChanged.connect(func(type: int):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.leftWallType = type as RoadMeshGenerator.WallTypes
	)

	roadPropertiesUI.leftWallStartHeightChanged.connect(func(height: float):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.leftWallStartHeight = height
	)

	roadPropertiesUI.leftWallEndHeightChanged.connect(func(height: float):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.leftWallEndHeight = height
	)

	roadPropertiesUI.leftRunoffMaterialChanged.connect(func(material: int):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.leftRunoffSurfaceType = material as PhysicsSurface.SurfaceType
	)

	roadPropertiesUI.rightWallTypeChanged.connect(func(type: int):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.rightWallType = type as RoadMeshGenerator.WallTypes
	)

	roadPropertiesUI.rightWallStartHeightChanged.connect(func(height: float):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.rightWallStartHeight = height
	)

	roadPropertiesUI.rightWallEndHeightChanged.connect(func(height: float):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.rightWallEndHeight = height
	)

	roadPropertiesUI.rightRunoffMaterialChanged.connect(func(material: int):
		if map.lastRoadElement == null:
			return

		map.lastRoadElement.rightRunoffSurfaceType = material as PhysicsSurface.SurfaceType
	)

	# pipe node properties ui

	pipeNodePropertiesUI.profileChanged.connect(func(profile: float):
		if currentElement == null || ClassFunctions.getClassName(currentElement) != "PipeNode":
			return
		
		currentElement = currentElement as PipeNode
		currentElement.profile = profile
	)

	pipeNodePropertiesUI.radiusChanged.connect(func(radius: float):
		if currentElement == null || ClassFunctions.getClassName(currentElement) != "PipeNode":
			return
		
		currentElement = currentElement as PipeNode
		currentElement.radius = radius
	)

	pipeNodePropertiesUI.flatChanged.connect(func(flat: bool):
		if currentElement == null || ClassFunctions.getClassName(currentElement) != "PipeNode":
			return
		
		currentElement = currentElement as PipeNode
		currentElement.flat = flat
	)


	# pipe properties ui

	pipePropertiesUI.pipeSurfaceChanged.connect(func(surface: int):
		if map.lastPipeElement == null:
			return

		map.lastPipeElement.surfaceType = surface as PhysicsSurface.SurfaceType
	)

	# scenery editor ui

	inputHandler.mouseMovedTo_Scenery.connect(
		map.onInputHandler_mouseMovedTo
	)

	sceneryEditorUI.modeChanged.connect(func(mode: int):
		map.setEditMode(mode)
	)

	sceneryEditorUI.directionChanged.connect(func(direction: int):
		map.setEditDirection(direction)
	)

	sceneryEditorUI.brushSizeChanged.connect(func(size: int):
		map.setBrushSize(size)
	)

	sceneryEditorUI.timeChanged.connect(func(time: float):
		map.setDayTime(time)
	)

	sceneryEditorUI.cloudChanged.connect(func(cloud: float):
		map.setCloudiness(cloud)
	)

	sceneryEditorUI.gloomyChanged.connect(func(gloomy: float):
		map.setGloomyness(gloomy)
	)

	sceneryEditorUI.groundSizeChanged.connect(func(size: int):
		map.setGroundSize(size)
	)

func setUIVisibility():
	roadNodePropertiesUI.visible = currentBuildMode == BuildMode.ROAD && currentEditorMode == EditorMode.BUILD
	roadPropertiesUI.visible = currentBuildMode == BuildMode.ROAD && currentEditorMode == EditorMode.BUILD

	pipeNodePropertiesUI.visible = currentBuildMode == BuildMode.PIPE && currentEditorMode == EditorMode.BUILD
	pipePropertiesUI.visible = currentBuildMode == BuildMode.PIPE && currentEditorMode == EditorMode.BUILD

	sceneryEditorUI.visible = currentEditorMode == EditorMode.SCENERY

func setCurrentElement():
	if currentEditorMode == EditorMode.BUILD:
		roadNode.visible = currentBuildMode == BuildMode.ROAD
		pipeNode.visible = currentBuildMode == BuildMode.PIPE

		if currentBuildMode == BuildMode.ROAD:
			currentElement = roadNode
		elif currentBuildMode == BuildMode.PIPE:
			currentElement = pipeNode
		else:
			print("[EditorEventListener.gd] Build Mode Not Implemented Yet!")
			currentElement = null
		return
	
	currentElement = null


var maxRaycastDistance: int = 2000

func screenPointToRay() -> Node3D:
	var spaceState = get_world_3d().direct_space_state

	var mousePos = get_viewport().get_mouse_position()
	var camera = get_tree().root.get_camera_3d()
	var from = camera.project_ray_origin(mousePos)
	var to = from + camera.project_ray_normal(mousePos) * maxRaycastDistance
	var rayArray = spaceState.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	
	if rayArray.has("collider"):
		return rayArray["collider"]
	return null


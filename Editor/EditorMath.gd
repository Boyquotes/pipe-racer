class_name EditorMath

static func getCurveLerp(
	start: Vector3, 
	startTangent: Vector3, 
	end: Vector3,
	endTangent: Vector3,
	t: float
) -> Vector3:
	var start2D: Vector2 = Vector2(start.x, start.z)
	var end2D: Vector2 = Vector2(end.x, end.z)
	var startTangent2D: Vector2 = Vector2(startTangent.x, startTangent.z).normalized()
	var endTangent2D: Vector2 = Vector2(endTangent.x, endTangent.z).normalized()

	var intersection = Geometry2D.line_intersects_line(
		start2D, 
		startTangent2D, 
		end2D,
		endTangent2D
	)

	if intersection == null:

		var endPerpenicular = Vector2(-endTangent2D.y, endTangent2D.x)
		intersection = Geometry2D.line_intersects_line(
			start2D, 
			startTangent2D, 
			end2D,
			endPerpenicular
		)
		var node1 = lerp(start2D, intersection, 0.5)
		var node2 = (start2D - node1) + end2D

		var p1: Vector2 = lerp(start2D, node1, t)
		var p2: Vector2 = lerp(node1, node2, t)
		var p3: Vector2 = lerp(node2, end2D, t)

		var p4: Vector2 = lerp(p1, p2, t)
		var p5: Vector2 = lerp(p2, p3, t)

		var p6: Vector2 = lerp(p4, p5, t)

		return Vector3(p6.x, 0, p6.y)
	else:
		# bezier curve
		var p1: Vector2 = lerp(start2D, intersection, t)
		var p2: Vector2 = lerp(intersection, end2D, t)
		var p3: Vector2 = lerp(p1, p2, t)

		return Vector3(p3.x, 0, p3.y)


const HAX_HEIGHT_ERROR: float = 0.001
const MAX_ITERATION_COUNT: int = 50

static func getHeightLerp(
	length: float,
	startHeight: float,
	startAngle: float,
	endHeight: float,
	endAngle: float,
	t: float
) -> Vector3:
	var startPos: Vector2 = Vector2(0, startHeight)
	var endPos: Vector2 = Vector2(length, endHeight)

	var startTangent: Vector2 = Vector2.RIGHT.rotated(-startAngle)
	var endTangent: Vector2 = Vector2.RIGHT.rotated(-endAngle)

	var intersection = Geometry2D.line_intersects_line(
		startPos, 
		startTangent, 
		endPos,
		endTangent
	)

	if intersection == null:
		var endPerpenicular = Vector2(-endTangent.y, endTangent.x)
		intersection = Geometry2D.line_intersects_line(
			startPos, 
			startTangent, 
			endPos,
			endPerpenicular
		)
		var node1 = lerp(startPos, intersection, 0.5)
		var node2 = (startPos - node1) + endPos

		var p1: Vector2 = lerp(startPos, node1, t)
		var p2: Vector2 = lerp(node1, node2, t)
		var p3: Vector2 = lerp(node2, endPos, t)

		var p4: Vector2 = lerp(p1, p2, t)
		var p5: Vector2 = lerp(p2, p3, t)

		var p6: Vector2 = lerp(p4, p5, t)

		return Vector3(0, p6.y, 0)
	else:
		# bezier curve
		var p1: Vector2 = lerp(startPos, intersection, t)
		var p2: Vector2 = lerp(intersection, endPos, t)
		var p3: Vector2 = lerp(p1, p2, t)

		if intersection.x < 0 or intersection.x > length:
			return Vector3(0, p3.y, 0)
		
		var expectedPoint: float = length * t
		var heightError: float = abs(p3.x - expectedPoint)
		
		var iter: int = 0
		while heightError > HAX_HEIGHT_ERROR && iter < MAX_ITERATION_COUNT:
			var newT = t + (expectedPoint - p3.x) / length
			p1 = lerp(startPos, intersection, newT)
			p2 = lerp(intersection, endPos, newT)
			p3 = lerp(p1, p2, newT)
			t = newT
			heightError = abs(p3.x - expectedPoint)
			iter += 1
		# print("[PipeMeshGenerator.gd] Height Bezier iterations: ", iter, " - Error: ", heightError)
		return Vector3(0, p3.y, 0) 

static func positionsMatch(
	node_a: Node3D,
	node_b: Node3D
) -> bool:
	return node_a.global_position == node_b.global_position \
		&& node_a.global_rotation == node_b.global_rotation 

const INTERSECT_EXTENTS: float = 64 * PrefabConstants.TRACK_WIDTH 

static func get3DBezierLerp(
	start: Vector3, 
	startTangent: Vector3, 
	end: Vector3,
	endTangent: Vector3,
	t: float
) -> Vector3:
	var control1 := Vector3.ZERO
	var control2 := Vector3.ZERO

	if (end - start).normalized().is_equal_approx(startTangent): # straight line
		return lerp(start, end, t)
	elif startTangent.is_equal_approx(endTangent): # parallel
		var corner: Vector3 = Geometry3D.get_closest_point_to_segment_uncapped(
			end,
			start,
			start + startTangent
		)
			
		control1 = start + startTangent * (corner - start).length() * 0.5
		control2 = end - endTangent * (corner - start).length() * 0.5
	else:
		var points := Geometry3D.get_closest_points_between_segments(
			start - startTangent * INTERSECT_EXTENTS,
			start + startTangent * INTERSECT_EXTENTS,
			end - endTangent * INTERSECT_EXTENTS,
			end + endTangent * INTERSECT_EXTENTS
		)

		control1 = points[0]
		control2 = points[1]


		control1 = lerp(start, control1, 0.6)
		control2 = lerp(end, control2, 0.6)

		# print("[EditorMath.gd] get3DBezierLerp points: ", points)
		# if t == 0:
		# 	print("[EditorMath.gd] get3DBezierLerp: control points: ", control1, control2)

		# if control1.is_equal_approx(control2):
		# 	if t == 0:
		# 		print("[EditorMath.gd] get3DBezierLerp: control points are equal")



	var p1: Vector3 = lerp(start, control1, t)
	var p2: Vector3 = lerp(control1, control2, t)
	var p3: Vector3 = lerp(control2, end, t)

	var p4: Vector3 = lerp(p1, p2, t)
	var p5: Vector3 = lerp(p2, p3, t)

	return lerp(p4, p5, t)
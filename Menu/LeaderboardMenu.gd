extends Control
class_name LeaderboardMenu

@onready var totalTimesGrid: GridContainer = %TotalTimesGrid

var totalTimes: Array = []

@onready var bestLapsGrid: GridContainer = %BestLapsGrid

var bestLaps: Array = []

signal addOnlineGhost(replayId: String)
signal removeOnlineGhost(replayId: String)

# func _ready():
# 	fetchTimes("650c73d0c3b8efa6383dde32")

func fetchTimes(trackId: String):
	fetchBestLaps(trackId)
	fetchBestTimes(trackId)

func fetchBestLaps(trackId: String):
	# bestLapsGrid.clear()
	# bestLapsGrid.add_item("Loading...")
	setTotalTimesLoading(true)
	var bestLapsRequest = HTTPRequest.new()
	add_child(bestLapsRequest)
	bestLapsRequest.timeout = 10
	bestLapsRequest.request_completed.connect(onBestLaps_RequestCompleted)

	var httpError = bestLapsRequest.request(
		Backend.BACKEND_IP_ADRESS + "/api/leaderboard/" + trackId + "?sortByLap=true"
	)
	if httpError != OK:
		print("Error: " + error_string(httpError))

func setTotalTimesLoading(loading: bool):
	for label in totalTimesGrid.get_children():
		if label.name == "LoadingLabel":
			label.visible = loading
		else:
			totalTimesGrid.remove_child(label)
			label.queue_free()

func fetchBestTimes(trackId: String):
	# bestTimesList.clear()
	# bestTimesList.add_item("Loading...")
	setBestLapsLoading(true)
	var bestTimesRequest = HTTPRequest.new()
	add_child(bestTimesRequest)
	bestTimesRequest.timeout = 10
	bestTimesRequest.request_completed.connect(onBestTimes_RequestCompleted)

	var httpError = bestTimesRequest.request(
		Backend.BACKEND_IP_ADRESS + "/api/leaderboard/" + trackId + "?sortByLap=false"
	)
	if httpError != OK:
		print("Error: " + error_string(httpError))

func setBestLapsLoading(loading: bool):
	for label in bestLapsGrid.get_children():
		if label.name == "LoadingLabel":
			label.visible = loading
		else:
			bestLapsGrid.remove_child(label)
			label.queue_free()

func onBestLaps_RequestCompleted(result: int, _responseCode: int, _headers: PackedStringArray, body: PackedByteArray):
	if _responseCode != 200:
		print("Error: ", _responseCode)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	# bestLapsGrid.clear()
	setBestLapsLoading(false)
	if data.size() == 0:
		var label = Label.new()
		label.text = "No records yet"
		bestLapsGrid.add_child(label)
		return

	addBestLapsHeaders()

	var placement = 1
	for record in data:
		# var item: String = str(placement) + ". "
		# item +=  record["user"]["username"] + " - " 
		# item += IngameHUD.getTimeStringFromTicks(record["bestLap"])
		# item += " (" + record["date"].split("T")[0] + ")"
		# bestLapsGrid.add_item(item)
		var placementLabel = Label.new()
		placementLabel.text = str(placement) + "."
		bestLapsGrid.add_child(placementLabel)

		var usernameLabel = Label.new()
		usernameLabel.text = record["user"]["username"]
		bestLapsGrid.add_child(usernameLabel)

		var timeLabel = Label.new()
		timeLabel.text = IngameHUD.getTimeStringFromTicks(record["bestLap"])
		bestLapsGrid.add_child(timeLabel)

		var dateLabel = Label.new()
		dateLabel.text = record["date"].split("T")[0]
		bestLapsGrid.add_child(dateLabel)

		var ghostButton = Button.new()
		ghostButton.toggle_mode = true
		if record.has('replay'):
			ghostButton.text = "Race"
			ghostButton.toggled.connect(func(toggled: bool):
				var replayId = record["replay"]
				if toggled:
					if isReplayDownloaded(replayId):
						addOnlineGhost.emit(replayId)
					else:
						var replayDownloadRequest = HTTPRequest.new()
						add_child(replayDownloadRequest)
						replayDownloadRequest.timeout = 10
						replayDownloadRequest.request_completed.connect(func(_result: int, responseCode: int, _headers: PackedStringArray, body: PackedByteArray):
							if responseCode != 200:
								print("Error downloading replay: ", body.get_string_from_utf8())
								ghostButton.disabled = false
								ghostButton.button_pressed = false
								return
							
							var filePath = "user://replays/downloaded/" + replayId + ".replay"
							var fileAccess = FileAccess.open(filePath, FileAccess.WRITE)

							if fileAccess == null:
								print("Error opening file: ", filePath)
								return

							fileAccess.store_buffer(body)
							fileAccess.close()
							ghostButton.disabled = false
							addOnlineGhost.emit(replayId)
						)

						ghostButton.disabled = true

						var httpError = replayDownloadRequest.request(
							Backend.BACKEND_IP_ADRESS + "/api/replays/" + replayId,
							[
								"Session-Token: " + GlobalProperties.SESSION_TOKEN,
							]
						)
						if httpError != OK:
							print("Error: " + error_string(httpError))
							ghostButton.disabled = false
							ghostButton.button_pressed = false

				else:
					removeOnlineGhost.emit(replayId)
			)
		else:
			ghostButton.text = "No replay"
			ghostButton.disabled = true
		bestLapsGrid.add_child(ghostButton)

		placement += 1

func addBestLapsHeaders():
	var placementLabel = Label.new()
	placementLabel.text = "#"
	bestLapsGrid.add_child(placementLabel)

	var usernameLabel = Label.new()
	usernameLabel.text = "Player"
	bestLapsGrid.add_child(usernameLabel)

	var timeLabel = Label.new()
	timeLabel.text = "Time"
	bestLapsGrid.add_child(timeLabel)

	var dateLabel = Label.new()
	dateLabel.text = "Date"
	bestLapsGrid.add_child(dateLabel)

	var ghostLabel = Label.new()
	ghostLabel.text = "Ghost"
	bestLapsGrid.add_child(ghostLabel)

func onBestTimes_RequestCompleted(result: int, _responseCode: int, _headers: PackedStringArray, body: PackedByteArray):
	if _responseCode != 200:
		print("Error: ", _responseCode)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	# totalTimesGrid.clear()
	setTotalTimesLoading(false)

	if data.size() == 0:
		var label = Label.new()
		label.text = "No records yet"
		totalTimesGrid.add_child(label)
		return
	
	addTotalTimesHeaders()

	var placement = 1
	for record in data:
		# var item: String = str(placement) + ". "
		# item +=  record["user"]["username"] + " - " 
		# item += IngameHUD.getTimeStringFromTicks(record["totalTime"])
		# item += " (" + record["date"].split("T")[0] + ")"
		# totalTimesGrid.add_item(item)
		var placementLabel = Label.new()
		placementLabel.text = str(placement) + "."
		totalTimesGrid.add_child(placementLabel)

		var usernameLabel = Label.new()
		usernameLabel.text = record["user"]["username"]
		totalTimesGrid.add_child(usernameLabel)

		var timeLabel = Label.new()
		timeLabel.text = IngameHUD.getTimeStringFromTicks(record["time"])
		totalTimesGrid.add_child(timeLabel)

		var dateLabel = Label.new()
		dateLabel.text = record["date"].split("T")[0]
		totalTimesGrid.add_child(dateLabel)
		placement += 1

		var ghostButton = Button.new()
		ghostButton.toggle_mode = true
		if record.has('replay'):
			ghostButton.text = "Race"
			ghostButton.toggled.connect(func(toggled: bool):
				var replayId = record["replay"]
				if toggled:
					if isReplayDownloaded(replayId):
						addOnlineGhost.emit(replayId)
					else:
						var replayDownloadRequest = HTTPRequest.new()
						add_child(replayDownloadRequest)
						replayDownloadRequest.timeout = 10
						replayDownloadRequest.request_completed.connect(func(_result: int, responseCode: int, _headers: PackedStringArray, body: PackedByteArray):
							if responseCode != 200:
								print("Error downloading replay: ", body.get_string_from_utf8())
								ghostButton.disabled = false
								ghostButton.button_pressed = false
								return
							
							var filePath = "user://replays/downloaded/" + replayId + ".replay"
							var fileAccess = FileAccess.open(filePath, FileAccess.WRITE)

							if fileAccess == null:
								print("Error opening file: ", filePath)
								return

							fileAccess.store_buffer(body)
							fileAccess.close()
							ghostButton.disabled = false
							addOnlineGhost.emit(replayId)
						)

						ghostButton.disabled = true

						var httpError = replayDownloadRequest.request(
							Backend.BACKEND_IP_ADRESS + "/api/replays/" + replayId,
							[
								"Session-Token: " + GlobalProperties.SESSION_TOKEN,
							]
						)
						if httpError != OK:
							print("Error: " + error_string(httpError))
							ghostButton.disabled = false
							ghostButton.button_pressed = false

				else:
					removeOnlineGhost.emit(replayId)
			)
		else:
			ghostButton.text = "No replay"
			ghostButton.disabled = true
		totalTimesGrid.add_child(ghostButton)


func addTotalTimesHeaders():
	var placementLabel = Label.new()
	placementLabel.text = "#"
	totalTimesGrid.add_child(placementLabel)

	var usernameLabel = Label.new()
	usernameLabel.text = "Player"
	totalTimesGrid.add_child(usernameLabel)

	var timeLabel = Label.new()
	timeLabel.text = "Time"
	totalTimesGrid.add_child(timeLabel)

	var dateLabel = Label.new()
	dateLabel.text = "Date"
	totalTimesGrid.add_child(dateLabel)

	var ghostLabel = Label.new()
	ghostLabel.text = "Ghost"
	totalTimesGrid.add_child(ghostLabel)

func isReplayDownloaded(replayId: String) -> bool:
	var replayPath = "user://replays/downloaded/" + replayId + ".replay"
	var dirAccess = DirAccess.open("user://")
	if dirAccess == null:
		return false
	return dirAccess.file_exists(replayPath)

func downloadReplay(replayId: String):
	if isReplayDownloaded(replayId):
		return

	var replayDownloadRequest = HTTPRequest.new()
	add_child(replayDownloadRequest)
	replayDownloadRequest.timeout = 10
	replayDownloadRequest.request_completed.connect(func(_result: int, responseCode: int, _headers: PackedStringArray, body: PackedByteArray):
		if responseCode != 200:
			print("Error downloading replay: ", body.get_string_from_utf8())
			return
		
		var filePath = "user://replays/downloaded/" + replayId + ".replay"
		var fileAccess = FileAccess.open(filePath, FileAccess.WRITE)

		if fileAccess == null:
			print("Error opening file: ", filePath)
			return

		fileAccess.store_buffer(body)
		fileAccess.close()
	)

	var httpError = replayDownloadRequest.request(
		Backend.BACKEND_IP_ADRESS + "/api/replays/" + replayId,
		[
			"Session-Token: " + GlobalProperties.SESSION_TOKEN,
		]
	)
	if httpError != OK:
		print("Error: " + error_string(httpError))
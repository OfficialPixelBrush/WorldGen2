extends GridMap

@export var worldSize : int;
@export var chunkSize : int;
@export var threshold : float;
@export var seed: int;
@export var invert: bool;

var xSeed = seed ^ 5123653463452423
var ySeed = seed ^ 8678565624745634
var zSeed = seed ^ 9812654375124121

# Large prime numbers for mixing
const PRIME1 = 0x85297A4D
const PRIME2 = 0x68E31DA4
const PRIME3 = 0xB5297A4D
const PRIME4 = 0x45D9F3B3
	
# Bit mixing function
func mix(a: int, b: int) -> int:
	return ((a ^ b) * PRIME1) & 0xFFFFFFFF

func spatial_prng(position: Vector3i, seed: int = 0) -> int:
	var x = position.x;
	var y = position.y;
	var z = position.z;
	# Initial hash
	var h = seed & 0xFFFFFFFF
	
	# Mix X coordinate
	h = mix(h, x * PRIME1)
	h = ((h << 13) | (h >> 19)) & 0xFFFFFFFF
	
	# Mix Y coordinate
	h = mix(h, y * PRIME2)
	h = ((h << 17) | (h >> 15)) & 0xFFFFFFFF
	
	# Mix Z coordinate
	h = mix(h, z * PRIME3)
	h = ((h << 11) | (h >> 21)) & 0xFFFFFFFF
	
	# Final mixing
	h = mix(h, h >> 16)
	h = mix(h, h >> 8)
	h *= PRIME4
	h ^= h >> 11
	h *= PRIME1
	
	return h & 0x7FFFFFFF  # Ensure positive number

func limitBounds(value,maxValue):
	while (value < 0):
		value += maxValue
	while (value > maxValue-1):
		value -= maxValue
	return value

func localToGlobalPosition(index: Vector3i,position: Vector3i):
	return Vector3i(index.x*chunkSize + position.x, index.y*chunkSize + position.y, index.z*chunkSize + position.z)

func getPointPositionInChunk(position: Vector3i):
	#var hashed = Vector3i(hash(position.x)%chunkSize,hash(position.y)%chunkSize,hash(position.z)%chunkSize)
	#print(str(position) + "->" + str(hashed))
	var spaceX = spatial_prng(position, xSeed);
	var spaceY = spatial_prng(position, ySeed);
	var spaceZ = spatial_prng(position, zSeed);
	#print(str(position) + "->" + str(Vector3i((spaceX^position.x)%16,(spaceY^position.y)%16,(spaceZ^position.z)%16)));
	return Vector3i((spaceX^position.x)%chunkSize,(spaceY^position.y)%chunkSize,(spaceZ^position.z)%chunkSize) #Vector3i(hash(position.x)%chunkSize,hash(position.y)%chunkSize,hash(position.z)%chunkSize)

func findDistance(chunkIndex: Vector3i,chunkPosition: Vector3i):
	var globalPosition = localToGlobalPosition(chunkIndex,chunkPosition)
	var smallestDistance = INF
	for z in range(-1,2,1):
		for y in range(-1,2,1):
			for x in range(-1,2,1):
				var goalIndex = chunkIndex + Vector3i(x,y,z)
				# Limit within bounds
				# TODO: Remove wrap-around for infinite worlds!!
				#var goalIndexCheck = Vector3i(limitBounds(goalIndex.x, worldSize), limitBounds(goalIndex.y,worldSize), limitBounds(goalIndex.z,worldSize))
				# print(goalIndex)
				# Get Distance
				var goalPosition = getPointPositionInChunk(goalIndex)
				var goalGlobalPosition = localToGlobalPosition(goalIndex,goalPosition)
				var distance = globalPosition.distance_to(goalGlobalPosition)
				if (distance < smallestDistance):
					smallestDistance = distance
	return smallestDistance

func updateChunk(chunkIndex: Vector3i):
	for z in range(chunkSize):
		for y in range(chunkSize):
			for x in range(chunkSize):
				var chunkPosition = Vector3i(x,y,z)
				var distance = findDistance(chunkIndex,chunkPosition)
				var globalPosition = localToGlobalPosition(chunkIndex,chunkPosition)
				#var pos = Vector3i(x-halfWorldSize,0,z-halfWorldSize)+
				if (invert):
					if (distance > threshold):
						set_cell_item(globalPosition,0);
				else:
					if (distance < threshold):
						set_cell_item(globalPosition,0);

func updateChunks():
	for chunkZ in range(worldSize):
		for chunkY in range(worldSize):
			for chunkX in range(worldSize):
				updateChunk(Vector3i(chunkX,chunkY,chunkZ))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updateChunks()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#updateChunk(Vector3i(0,0,0));
	pass

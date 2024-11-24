extends GridMap

@export var worldSize : int;
@export var chunkSize : int;
@export var threshold : float;
@export var seed: int;
@export var invert: bool;
@export var origin: Vector3i;

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
func findDistance(chunkIndex: Vector3i, chunkPosition: Vector3i, scale: int):
	var globalPosition = localToGlobalPosition(chunkIndex, chunkPosition)
	var smallestDistance = INF
	var y = 0
	
	# Check neighboring chunks
	for z in range(-1, 2, 1):
		for x in range(-1, 2, 1):
			var goalIndex = chunkIndex + Vector3i(x, y, z)
			
			# Fix point position calculation for negative chunks
			var goalPosition = getPointPositionInChunk(goalIndex, scale)
			# Ensure positive modulo result
			goalPosition.x = ((goalPosition.x % chunkSize) + chunkSize) % chunkSize
			goalPosition.y = ((goalPosition.y % chunkSize) + chunkSize) % chunkSize
			goalPosition.z = ((goalPosition.z % chunkSize) + chunkSize) % chunkSize
			
			var goalGlobalPosition = localToGlobalPosition(goalIndex, goalPosition)
			var distance = globalPosition.distance_to(goalGlobalPosition)
			if distance < smallestDistance:
				smallestDistance = distance
	
	return smallestDistance

# You might also need to update getPointPositionInChunk to handle negative numbers:
func getPointPositionInChunk(position: Vector3i, scale: int):
	var spaceX = spatial_prng(position, xSeed)
	var spaceY = spatial_prng(position, ySeed)
	var spaceZ = spatial_prng(position, zSeed)
	
	# Ensure positive modulo results
	var x = ((spaceX ^ position.x) % scale + scale) % scale
	var y = ((spaceY ^ position.y) % scale + scale) % scale
	var z = ((spaceZ ^ position.z) % scale + scale) % scale
	
	return Vector3i(x, y, z)

func updateChunk(chunkIndex: Vector3i, resolution = 1):
	if (resolution > 7):
		resolution = 7
	if (resolution < 1):
		resolution = 1
	var y = 0
	for z in range(0,chunkSize, resolution):
		for x in range(0,chunkSize, resolution):
			var chunkPosition = Vector3i(x,y,z)
			var distance = findDistance(chunkIndex,chunkPosition,chunkSize)
			distance = distance + findDistance(chunkIndex,chunkPosition,chunkSize/2)/2
			distance = distance - findDistance(chunkIndex,chunkPosition,chunkSize/8)/2
			var globalPosition = localToGlobalPosition(chunkIndex,chunkPosition)
			#var pos = Vector3i(x-halfWorldSize,0,z-halfWorldSize)+
			if (distance > threshold):
				globalPosition.y += (distance-threshold)
				set_cell_item(globalPosition,resolution-1);

func updateChunks(origin):
	var chunkY = 0
	for chunkZ in range(worldSize*-1,worldSize,1):
		for chunkX in range(worldSize*-1,worldSize,1):
			var coordiante = Vector3i(chunkX,chunkY,chunkZ)
			var distance = coordiante.distance_to(origin)
			updateChunk(coordiante+origin,distance+1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updateChunks(origin)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#updateChunk(Vector3i(0,0,0));
	pass

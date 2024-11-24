import random
import pygame
import math

chunkSize = 128
worldSize = 2

pygame.init()

# Create a window
screen = pygame.display.set_mode((worldSize*chunkSize, worldSize*chunkSize))
pygame.display.set_caption("World Gen Test")

# Create a surface
texture = pygame.Surface((worldSize*chunkSize, worldSize*chunkSize))

pointList = [[(0, 0) for _ in range(worldSize)] for _ in range(worldSize)]

def getDistance(pos1, pos2):
    return math.sqrt(pow(pos2[0]-pos1[0],2)+pow(pos2[1]-pos1[1],2))

def limitBounds(value,maxValue):
    inValue = value
    while (value < 0):
        value += maxValue
    while (value > maxValue-1):
        value -= maxValue
    return value

def localToGlobalPosition(pos,index):
    return (index[0]*chunkSize + pos[0], index[1]*chunkSize + pos[1])

def findDistance(chunkIndex,globalPosition):
    smallestDistance = 100000000
    for y in range(-1,2,1):
        for x in range(-1,2,1):
            goalIndex = (chunkIndex[0] + x,chunkIndex[1] + y)
            # Limit within bounds
            goalIndexCheck = (limitBounds(goalIndex[0], worldSize), limitBounds(goalIndex[1],worldSize))
            #print(goalIndex)
            # Get Distance
            goalPosition = pointList[goalIndexCheck[0]][goalIndexCheck[1]]

            goalGlobalPosition = localToGlobalPosition(goalPosition,goalIndex)

            distance = getDistance(globalPosition,goalGlobalPosition)
            if (distance < smallestDistance):
                smallestDistance = distance
    return round(smallestDistance)

def spatial_prng(x: int, y: int, z: int, seed: int = 0) -> int:
    """
    Generate a pseudorandom number based on spatial coordinates and a seed.
    Uses a combination of bit manipulation and prime numbers for high-quality randomness.
    
    Args:
        x, y, z: Spatial coordinates
        seed: Optional seed value for consistent generation
        
    Returns:
        A pseudorandom integer that appears random but is deterministic for the same inputs
    """
    # Large prime numbers for mixing
    PRIME1 = 0x85297A4D
    PRIME2 = 0x68E31DA4
    PRIME3 = 0xB5297A4D
    PRIME4 = 0x45D9F3B3
    
    # Bit mixing function
    def mix(a: int, b: int) -> int:
        return ((a ^ b) * PRIME1) & 0xFFFFFFFF
    
    # Initial hash
    h = seed & 0xFFFFFFFF
    
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

seed = 23542353456
xSeed = seed ^ 58921384723423051
ySeed = seed ^ 90712709409345236

#for i in range(10):
#    print(str(i) + "->" + str(pseudorand(i,seed)%16))

# Fill pixels
for y in range(worldSize):
    xList = []
    for x in range(worldSize):
        z = 0
        posX = spatial_prng(x,y,z,xSeed)%chunkSize#random.randint(0, chunkSize-1)
        posY = spatial_prng(x,y,z,ySeed)%chunkSize#random.randint(0, chunkSize-1)
        xList.append((posX,posY))
        pointList[x][y] = (posX,posY)
        texture.set_at((x*chunkSize + posX, y*chunkSize + posY), (255,0,0))  # Set RGB values
    #print(xList)

#mouse_pos = pygame.mouse.get_pos()
for chunkY in range(worldSize):
    for chunkX in range(worldSize):
        for y in range(chunkSize):
            for x in range(chunkSize):
                #mouse_pos = pygame.mouse.get_pos()
                #chunkX = math.floor(mouse_pos[0] / chunkSize)
                #chunkY = math.floor(mouse_pos[1] / chunkSize)
                pos = (chunkX*chunkSize + x, chunkY*chunkSize + y)
                distance = findDistance((chunkX,chunkY),pos)
                if distance == 0:
                    texture.set_at(pos, (255,0,0))  # Set RGB values
                else:
                    texture.set_at(pos, (distance,distance,distance))  # Set RGB values

# Main loop
running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    screen.blit(texture, (0, 0))  # Render texture to the screen
    pygame.display.flip()

pygame.quit()
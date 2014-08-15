## @package randPaths
## @author Siddarth Srinivasan (UCLA REU 2014)
## @date 28th July 2014
## @brief  A simple script to generate NUM_PATHS sets of (x, y) coordinates,
#		   where each point is at least MAG away from the previous point.
import random
import math

# Test bed boundaries
x_min = 100
y_min = 120
x_max = 540
y_max = 760

NUM_PATHS = 226
MAG = 300

paths = []
paths += [(random.randint(x_min, x_max), random.randint(y_min, y_max))]

for i in range(1, NUM_PATHS):
    newPath = (random.randint(x_min, x_max), random.randint(y_min, y_max))
    while (math.sqrt((newPath[0] - paths[i-1][0])**2 + \
                      (newPath[1] - paths[i-1][1])**2) < MAG):
        newPath = (random.randint(x_min, x_max), random.randint(y_min, y_max))

    paths += [newPath]

return paths
    

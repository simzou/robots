import random
import math

x_min = 100
y_min = 120
x_max = 540
y_max = 760

MAG = 300

paths = []

paths += [(random.randint(x_min, x_max), random.randint(y_min, y_max))]

for i in range(1, 226):
    newPath = (random.randint(x_min, x_max), random.randint(y_min, y_max))
    while (math.sqrt((newPath[0] - paths[i-1][0])**2 + \
                      (newPath[1] - paths[i-1][1])**2) < MAG):
        newPath = (random.randint(x_min, x_max), random.randint(y_min, y_max))

    paths += [newPath]

print paths
    

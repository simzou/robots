import math
import operator

def determineRobotMovement(startX, startY, theta, endX, endY):
	"""
		Function takes in the robot's starting position and heading and the 
		ending location and returns	the angle to turn (between -pi to pi) and 
		the distance between the two points (i.e. the distance for the robot
		to travel)
	"""

	def dotProduct(a, b):
		return sum(map( operator.mul, a, b))

	def crossProduct(a, b):
	    c = [a[1]*b[2] - a[2]*b[1],
	         a[2]*b[0] - a[0]*b[2],
	         a[0]*b[1] - a[1]*b[0]]
	    return c

	# a is the unit vector for the direction the robot is facing
	a = [math.cos(theta), math.sin(theta), 0]

	# b is the vector from start point to end point
	b = [endX - startX, endY - startY, 0]
	b_mag = math.sqrt(b[0]**2 + b[1]**2)

	# shouldn't happen, but in case our start and end points are the same
	if b_mag == 0:
		amountToTurn = 0.0
	else:
		# normalizing b
		b = [elem / float(b_mag) for elem in b]

		# a dot b = |a||b| cos (theta)
		amountToTurn = math.acos(dotProduct(a,b))

		# if the direction of the third element of the cross product is
		# negative, we turn right (so angle is negative), else we turn left
		c = crossProduct(a,b)
		if c[2] < 0:
			amountToTurn = amountToTurn * -1;
			print "turn right"
		else:
			print "turn left"
	
	distanceToTravel = b_mag
	print ("amountToTurn: %f" % amountToTurn)
	print ("distanceToTravel: %f" % distanceToTravel)
	return (amountToTurn, distanceToTravel)



if __name__ == "__main__":
    assert (determineRobotMovement(0,0,math.pi/4,0,5)[0] > 0)
    assert (determineRobotMovement(0,0,math.pi/4,0,5)[1] == 5)
    assert (determineRobotMovement(0,0,0,-3,0)[1] == 3)
    assert (determineRobotMovement(0,0,0,-3,0)[0] - math.pi == 0)
    assert (determineRobotMovement(0,0,math.pi/4,3,0)[0] < 0)
    assert (determineRobotMovement(0,0,math.pi/4,0,0)[0] == 0)

    assert (determineRobotMovement(0,0,math.pi/4,6,-5)[0] < 0)
    assert (determineRobotMovement(0,0,math.pi/4,-5,7)[0] > 0)

    determineRobotMovement(53, 74, 5.06, 360, 360)
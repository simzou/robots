#!/usr/bin/python

## Author: Siddarth Srinivasan, UCLA REU 2014
## Date Created: 8th July 2014
## Summary: Server-Side Script that handles communication with the robot. Saves
##          the requests from the robot, the data it collects and the robot's
##          position as tracked by the overhead video camera, to a MySQL DB.

## State Definitions:
#
# State 0: Arduino is asking if the video camera has its start position. If so,
#          the server will send a json response "True", telling the robot it can
#          begin its path. If not, the server will send a json response "False"
#          telling the robot that it has not been located, and so it should
#          wait.
# State 1: Arduino is asking if the video camera has its end position. If so,
#          the server will send a json response "True", telling the robot it can
#          move to the starting point of its new path. If not, the server will
#          send a json response "False" telling the robot that it has not
#          been located, and so it should wait.


## Error Codes:
#
# NO_ERROR_M -1     : No Error, but will travel a "maximum" distance instead of
#                    the directed distance. Note: If this error code is obtained
#                    time sent to the robot is 0, the robot is out of bounds.
# NO_ERROR_T 0      : No Error, robot should travel distnace to next point
# NNL_ERROR  1      : Not a New Location Error
# S_TIMEOUT_ERROR 2 : Serial Timeout Error


import cgi, cgitb
cgitb.enable()

import sys
sys.path.append("/Library/Frameworks/Python.framework/Versions/2.7/lib/" + 
                "python2.7/site-packages/")

import mysql.connector as conn
import time
import math
import operator
import random
import json
import serial

## Path Directions for the Robot

target = [
            (512, 100),
            (307, 712),
            (492, 263),
            (58,  544),
            (222, 628),
            (400, 139),
            (200, 252),
            (430, 673),
            (172, 401),
            (316, 629),
            (45, 138)
         ]
# target = [
#             (160, 160), #1
#             (160, 660), #2
#             (240, 660), #3
#             (240, 160), #4
#             (320, 160), #5
#             (320, 660), #6
#             (400, 660), #7
#             (400, 160), #8
#             (480, 160), #9
#             (480, 660), #10
#             (560, 660), #11
#             (560, 160), #12
#             (300, 300)  #13

#         ]
numTargets = len(target) - 1

## Constants Definitions

# Error Codes
NO_ERROR_M = -1
NO_ERROR_T = 0
NNL_ERROR = 1
S_TIMEOUT_ERROR = 2

TIMEOUT = 3          # Time in seconds to wait for serial data to be read
NUM_SERIAL_DATA = 4  # The number of points of information serial data carries

# Boundaries of the Test Bed
X_MIN = 40
Y_MIN = 80
X_MAX = 600
Y_MAX = 800

PXIELS_PER_SECOND = 160.0   # Pixels the robot covers in moving straight for 1s
RADS_PER_SECOND = 1.25      # Radians the robot covers in turning for 1s

RADIUS_CUTOFF = 25   # The minimum radius the robot needs to be from its start
                     # before its new position is registered

MIN_TIME_TO_TRAVEL = 1500  # The minimum time the robot will travel in any path

dbName = "Log1"  # The database to save to

NO_DATA = -1     # The dummy value to store in database if no data was collected

################################################################################
#                             HTML HANDLERS
################################################################################

## This is essentially for debugging purposes and browser interaction
def htmlForm():
    """
        Function that generates the html form if a state hasn't been submitted
        to the script. For all practical purposes, this is only when testing
        so the robot should never really 'see' this code.
    """

    print("""Content-type:text/html\n\n
            <!DOCTYPE html>
            <html lang="en">
                <head>
                    <meta charset="utf-8" />
                    <title>
                        Robot Server
                    </title>
                </head>
                <body>
                    <form method = "post" action = "robotServer.cgi">
                        Enter State:
                        <input type = "text" name = "state" autofocus = "true"/>
                        <br><br>

                        Enter Data:
                        <input type = "text" name = "data" />
                        <br><br>

                        <input type = "submit" name = "submitdata" value = 
                                      "Submit" />
                    </form> 
                </body>
            </html>""")


def htmlResponse():
    """
        This function declares that the response will be in json if a state has
        been submitted to the form.
    """

    print("""Content-type:application/json\n\n""")


def jsonResponse(response):
    """
        Returns the response in json form.

        response is a list, currently with only 1 element that informs the robot
        whether or not its request has been successful.
    """

    j = {
            'Response': response[0],
            'Duration': response[1],
            'Error Code': response[2]
        }

    print json.dumps(j, indent = 4, separators=(',', ': '))


################################################################################
#                               CAMERA HANDLERS
################################################################################

def locate():
    """
        Function that returns the x and y coordinates of the robot if it has
        been detected, and None and None otherwise. The data is read from the
        serial port, which comes in from the Wi232 transceiver which is
        transmitting data from the video camera. The data comes in the following
        format:
                *|x|y|theta|!---------------------------...
    """

    ser = serial.Serial('COM8', 115200, timeout=2, xonxoff=False,
                                                     rtscts=False, dsrdtr=False)
    ser.flushInput()
    ser.flushOutput()

    raw_data = ser.readline()

    # Set variables for timeout in case serial cable isn't connected
    t = time.time()

    # Read data
    while not raw_data and (time.time() - t < TIMEOUT):
        raw_data = ser.readline()

    if raw_data:
        ## Now, begin parsing the data
        startData = False  # Whether we are in 'reading' data mode
        locationIndex = 0  # Tracks entries from raw_data going to location_data
        locationData = [""] * NUM_SERIAL_DATA   # List for data read from serial
        loopIndex = 0

        # Loop over all of raw_data
        while loopIndex < len(raw_data):
            if raw_data[loopIndex] == "*":
                startData = True
            elif startData:
                if raw_data[loopIndex] == "|":
                    locationIndex += 1
                elif raw_data[loopIndex] == "!":
                    locationIndex = 0
                    break
                else:
                    locationData[locationIndex] += raw_data[loopIndex]
            loopIndex += 1

        ser.close()
        return locationData[1], locationData[2], locationData[3]
    else:
        ## Unable to read data from serial, so return None
        return None, None, None


def findMaxTime(x, y, theta):
    """
        Given the robot's position and heading, the function returns the max
        time for which the robot can travel before it will go off the edge.
        The time returned is expected to be the value used by the motors in
        driving the robot.
    """

    newX = x
    newY = y
    c = 0.5

    while (newX > X_MIN and newX < X_MAX and newY > Y_MIN and newY < Y_MAX):
        newX = x + c * math.cos(theta)
        newY = y + c * math.sin(theta)
        c = c + 0.5

    # return the magnitude, converted to milliseconds
    return int((c - 0.5)/PXIELS_PER_SECOND * 1000)


def findNextTime(startX, startY, theta, endX, endY):
    """
        Function takes in the robot's starting position and heading and the 
        ending location and returns the angle to turn (between -pi to pi) and 
        the distance between the two points (i.e. the distance for the robot
        to travel)
    """

    # a is the unit vector for the direction the robot is facing
    a = [math.cos(theta), math.sin(theta), 0]

    # b is the vector from robot to destination
    b = [endX - startX, endY - startY, 0]
    b_mag = math.sqrt(b[0]**2 + b[1]**2)

    # Shouldn't happen, but in case our start and end points are the same
    if b_mag == 0:
        amountToTurn = 0.0
        return 1000, 1000           # dummy values, no reason for 1000
    else:
        distanceToTravel = b_mag

        # Normalizing b
        b = [elem / float(b_mag) for elem in b]

        # a dot b = |a||b| cos (theta)
        amountToTurn = math.acos(dotProduct(a,b))

        # If the direction of the third element of the cross product is
        # negative, we turn right (so angle is negative), else we turn left
        c = crossProduct(a,b)
        if c[2] < 0:
            return (int((-amountToTurn)/RADS_PER_SECOND * 1000),
                    int(distanceToTravel/PXIELS_PER_SECOND * 1000))
        else:
            return (int((amountToTurn)/RADS_PER_SECOND * 1000),
                    int(distanceToTravel/PXIELS_PER_SECOND * 1000))


def dotProduct(a, b):
    """
        Helper function - dot product of two vectors a and b
    """
    return sum(map( operator.mul, a, b))

def crossProduct(a, b):
    """
        Helper function - cross product of two vectors a and b
    """
    c = [a[1]*b[2] - a[2]*b[1],
         a[2]*b[0] - a[0]*b[2],
         a[0]*b[1] - a[1]*b[0]]
    return c
    

################################################################################
#                             MySQL DATABASE HANDLERS
################################################################################

def connectDB(dbName):
    """
        Connects to the database with name 'dbName'
    """

    db = conn.connect(host = 'localhost', user = 'root', \
                      passwd = 'uclaRobots14', db = dbName)
    cursor = db.cursor()
    return db, cursor


def saveStateToDB(dbName, State, Data, currentX, currentY, theta, destX, destY,\
                  Response, Duration, Error_Code):
    """
        Called when the robot has contacted the server, it stores the state that
        the robot sent, along with other useful information to keep track of the
        robot's actions
    """

    db, cursor = connectDB(dbName)
    currentTime = time.ctime(time.time())

    sql = "INSERT INTO State_Record(Timestamp, State, Data, currentX, " + \
          "currentY, theta, destX, destY, Response, Duration, Error_Code) " + \
          "VALUES('" + currentTime + "' , " + str(State) + ", " + str(Data) + \
          ", " + str(currentX) + ", " + str(currentY) + ", " + str(theta) + \
          ", " + str(destX) + ", " + str(destY) + ", " + str(Response) + \
          ", " + str(Duration) + ", " + str(Error_Code) + ") "
    cursor.execute(sql)
    db.commit()


def saveStartToDB(dbName, startX, startY):
    """
        Called when the video camera has located the robot, and the robot was
        looking to start it path, it saves the starting coordinates of the robot
        to the database.

        ASSUMES that the previous entry has been completed.
    """

    db, cursor = connectDB(dbName)
    sql = "INSERT INTO Data_Collection(startX, startY) VALUES(" + str(startX) +\
          ", " + str(startY) + ")"
    cursor.execute(sql)
    db.commit()


def saveEndDataToDB(dbName, endX, endY, data, numDataPt):
    """
        Called when the video camera has located the robot, and the robot has
        completed its path, function saves the end coordinates of the robot
        along with the data it collected to the database
    """

    db, cursor = connectDB(dbName)
    sql = "update Data_Collection set endX = " + str(endX) + ", endY = " + \
          str(endY) + ", data = " + str(data) + " where DataPtID = " + \
          str(numDataPt)
    cursor.execute(sql)
    db.commit()


def numDataCollected(dbName):
    """
        Given the name of the database, returns the number of data points
        collected in the table Data_Collection
    """

    db, cursor = connectDB(dbName)
    sql = "SELECT COUNT(DataPtID) FROM Data_Collection"
    cursor.execute(sql)
    return cursor.fetchone()[0]


def inNewLocation(dbName, x, y, numDataPt):
    """
        Checks if the given x, y coordinates are outside some radius from the
        start coordinate of the robot during that data sample, and returns true
        if so
    """
    db, cursor = connectDB(dbName)
    sql = "SELECT startX, startY FROM `data_collection` WHERE DataPtID =" + \
          str(numDataPt)
    cursor.execute(sql)

    result = cursor.fetchone()
    newX = result[0]
    newY = result[1]
    mag = math.sqrt((newX - x)**2 + (newY - y)**2)

    return mag > RADIUS_CUTOFF


################################################################################
#                             MAIN PROGRAM
################################################################################

if __name__ == "__main__":
    try:       
        # Find the number of data points collected
        numDataPt = numDataCollected(dbName)

        # See if any form data about the has been submitted
        submittedData = cgi.FieldStorage()
        state = submittedData.getvalue("state")

        # If we do know the state, then a successful request has been made
        if state:
            htmlResponse()
            state = int(state)
            x, y, theta = locate()

            if x and y and theta:
                x = int(x)
                y = int(y)
                theta = float(theta)

                if state == 0:
                    maxTime = findMaxTime(x, y, theta)
                    _, timeToTravel = findNextTime(x, y, theta, 
                                  target[numDataPt % numTargets][0],
                                  target[numDataPt % numTargets][1])

                    saveStartToDB(dbName, x, y)

                    # Check whether the robot can actually move 'timeToTravel'
                    # to the next point, and respond appropriately. The reason
                    # the robot might have to travel for just maxTime instead of
                    # timeToTravel is that it might not have changed its heading
                    # very accurately.
                    if maxTime < timeToTravel:
                        nextTime = maxTime
                        saveStateToDB(dbName, state, NO_DATA, x, y, theta, \
                                      target[numDataPt % numTargets][0],   \
                                      target[numDataPt % numTargets][1],   \
                                      True, nextTime, NO_ERROR_M)
                        jsonResponse([True, nextTime, NO_ERROR_M])
                    else:
                        # time = random.randint(MIN_TIME_TO_TRAVEL, maxTime)
                        nextTime = timeToTravel
                        saveStateToDB(dbName, state, NO_DATA, x, y, theta, \
                                      target[numDataPt % numTargets][0],   \
                                      target[numDataPt % numTargets][1],   \
                                      True, nextTime, NO_ERROR_T)
                        jsonResponse([True, nextTime, NO_ERROR_T])

                elif state == 1:
                    data = int(submittedData.getvalue("data"))

                    # Check whether the camera has recognized that the robot has
                    # moved to a new location -- there is some lag between the
                    # robot moving and the camera locating it.
                    if inNewLocation(dbName, x, y, numDataPt):
                        timeToTurn, _ = findNextTime(x, y, theta,
                                        target[numDataPt % numTargets][0],
                                        target[numDataPt % numTargets][1])

                        saveEndDataToDB(dbName, x, y, data, numDataPt)
                        saveStateToDB(dbName, state, data, x, y, theta,    \
                                      target[numDataPt % numTargets][0],   \
                                      target[numDataPt % numTargets][1],   \
                                      True, timeToTurn, NO_ERROR_T)
                        jsonResponse([True, timeToTurn, NO_ERROR_T])
                    else:
                        saveStateToDB(dbName, state, data, x, y, theta, \
                                      target[numDataPt % numTargets][0],   \
                                      target[numDataPt % numTargets][1],   \
                                      False, 0, NNL_ERROR)
                        jsonResponse([False, 0, NNL_ERROR])

                else:
                    print "Error: Unknown State"

            # If the robot has sent a request but it has not been located,
            # respond to let it know not to move.
            else:
                saveStateToDB(dbName, state, NO_DATA, NO_DATA, NO_DATA,    \
                              NO_DATA, target[numDataPt % numTargets][0],  \
                              target[numDataPt % numTargets][1],           \
                              False, 0, S_TIMEOUT_ERROR)
                jsonResponse([False, 0, S_TIMEOUT_ERROR])

        # This is for the human-reader case, when no state has been submitted.
        else:
            htmlForm()

    except:
        cgi.print_exception()

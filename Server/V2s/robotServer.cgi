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

import cgi, cgitb
cgitb.enable()

import sys
sys.path.append("/Library/Frameworks/Python.framework/Versions/2.7/lib/" + 
                "python2.7/site-packages/")

import mysql.connector as conn
import time
import math
import random
import json
import serial


################################################################################
#                             HTML HANDLERS
################################################################################

## Eventually, we should not even need these.
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
            'Time': response[1]
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
                *|x|y|theta!---------------------------...
    """

    ser = serial.Serial('COM8', 115200, timeout=2, xonxoff=False,
                                                     rtscts=False, dsrdtr=False)
    ser.flushInput()
    ser.flushOutput()

    raw_data = ser.readline()
    t = time.time()
    TIMEOUT = 5
    # Read data
    while not raw_data and (time.time() - t < TIMEOUT):
        raw_data = ser.readline()

    if raw_data:
        ## Now, begin parsing the data
        startData = False  # whether we are in 'reading' data mode
        locationIndex = 0  # Tracks entries from raw_data going to location_data
        numCamData = 4     # The number of data points we will be tracking
        
        # List that stores the data from the camera
        locationData = [""] * numCamData

        loopIndex = 0       # Loop over all of raw_data
        while loopIndex < len(raw_data):
            # Only enter data 'reading' mode if raw_data contains the car we are
            # looking for
            if raw_data[loopIndex] == "*":
                startData = True
            # Upon entering data 'reading' mode check for end-of-data-packet and
            # end of single piece of data
            elif startData:
                if raw_data[loopIndex] == "|":
                    locationIndex += 1
                elif raw_data[loopIndex] == "!":
                    locationIndex = 0
                    break
                else:
                    locationData[locationIndex] += raw_data[loopIndex]
            loopIndex += 1

        #print locationData              ## FIXME! - Unnecessary printing
        ser.close()

        return locationData[1], locationData[2], locationData[3]
    else:
        return None, None, None


def findMaxTime(x, y, theta):
    """
        Given the robot's position and heading, the function returns the max
        time for which the robot can travel before it will go off the edge.
        The time returned is expected to be the value used by the motors in
        driving the robot.
    """

    x_min = 60
    y_min = 80
    x_max = 600
    y_max = 800

    pixelsPerSecond = 150.0
    newX = x
    newY = y
    c = 0.5

    while (newX > x_min and newX < x_max and newY > y_min and newY < y_max):
        newX = x + c * math.cos(theta)
        newY = y + c * math.sin(theta)
        c = c + 0.5

    # return the magnitude, converted to milliseconds
    return int((c - 0.5)/pixelsPerSecond * 1000)


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
    return db,cursor


def saveStateToDB(dbName, state):
    """
        Called when the robot has contacted the server, it stores the state that
        the robot sent
    """

    db, cursor = connectDB(dbName)
    currentTime = time.ctime(time.time())

    sql = "INSERT INTO State_Record(timestamp, state) VALUES('" + currentTime +\
          "' , " + str(state) + " ) "
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
          str(endY) + ", data = " + str(data) + " where dataptid = " + \
          str(numDataPt)
    cursor.execute(sql)
    db.commit()


def numDataCollected(dbName):
    """
        Given the name of the database, returns the number of data points
        collected in the table Data_Collection
    """

    db, cursor = connectDB(dbName)
    sql = "SELECT COUNT(dataptid) FROM Data_Collection"
    cursor.execute(sql)
    return cursor.fetchone()[0]


def inNewLocation(dbName, x, y, numDataPt):
    """
        Checks if the given x, y coordinates are outside some radius from the
        start coordinate of the robot during that data sample, and returns true
        if so
    """
    db, cursor = connectDB(dbName)
    sql = "SELECT startX, startY FROM `data_collection` WHERE dataptid=" + \
          str(numDataPt)
    cursor.execute(sql)

    RADIUS_CUTOFF = 75

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
        # The database to save to
        dbName = "Log2"

        # The number of data points collected
        numDataPt = numDataCollected(dbName)

        # The minimum time the robot will travel in any path
        minTimeToTravel = 700

        # See if any form data about the has been submitted
        submittedData = cgi.FieldStorage()
        state = submittedData.getvalue("state")

        # If we do know the state, then Arduino has made a successful request
        if state:                          # state is a string here, not bool
            htmlResponse()

            state = int(state)
            saveStateToDB(dbName, state)   # Record the state in the database
        
            x, y, theta = locate()

            # If the camera has located the Arduino
            if x and y and theta:
                x = int(x)
                y = int(y)
                theta = float(theta)
                # Save its position to the database, along with data if it has
                # been collected, and let the robot know.
                if state == 0:
                    saveStartToDB(dbName, x, y)

                    maxTime = findMaxTime(x, y, theta)
                    if maxTime < minTimeToTravel:
                        time = maxTime
                    else:
                        time = random.randint(minTimeToTravel, maxTime)
                    jsonResponse([True, time])
                    # print x, y

                elif state == 1:
                    if inNewLocation(dbName, x, y, numDataPt):
                        data = int(submittedData.getvalue("data"))
                        saveEndDataToDB(dbName, x, y, data, numDataPt)
                        jsonResponse([True, 1000])
                    else:
                        jsonResponse([False, 0])

                else:
                    print "Error: Unknown State"

            # If the robot has sent a request but it has not been located,
            # respond to let it know not to move.
            else:
                jsonResponse([False, 0])

        # This is for the human-reader case, when no state has been submitted.
        else:
            htmlForm()

    except:
        cgi.print_exception()

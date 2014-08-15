#!C:\Python27\python.exe

## @package robotServer
## @author Siddarth Srinivasan (UCLA REU 2014)
## @date 8th July 2014
## @brief   Server-Side Script that handles communication with the robot. Saves
#           the requests from the robot, the data it collects and the robot's
#           position (as tracked by the overhead video camera), to a MySQL DB.
#           A MATLAB script directs the robot where to go, using adaptive path
#           selection.
## @remarks State Definitions (as submitted to the server):
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
# 
# Error Codes:  The server reports these to the database with every response
#
# NO_ERROR_M -1     : No Error, but will travel a "maximum" distance instead of
#                    the directed distance. If this error code is obtained
#                    time sent to the robot is 0, the robot is out of bounds.
# NO_ERROR_T 0      : No Error, robot should travel distnace to next point
# NNL_ERROR  1      : Not a New Location Error
# S_TIMEOUT_ERROR 2 : Serial Timeout Error


import cgi, cgitb
cgitb.enable()

import mysql.connector as conn
import time
import math
import operator
import random
import json
import serial
import win32com.client

# Constants Definitions

# Boundaries of the Test Bed
X_MIN = 40
Y_MIN = 80
X_MAX = 600
Y_MAX = 800

# Error Codes
NO_ERROR_M = -1
NO_ERROR_T = 0
NNL_ERROR = 1
S_TIMEOUT_ERROR = 2

# Processing Serial Data and Robot's position
COM_PORT = 'COM6'    # COM port used to READ the incoming serial data
BAUD_RATE = 115200   # Rate at which information is sent to serial
SER_TIMEOUT = 2      # How long the serial connection should wait before timeout
TIMEOUT = 3          # Time in seconds to wait for serial data to be read
NUM_SERIAL_DATA = 4  # The number of points of information serial data carries
RADIUS_CUTOFF = 1    # The minimum radius the robot needs to be from its start
                     # before its new position is registered
MIN_TIME_TO_TRAVEL = 1500  # The minimum time the robot will travel in any path

# Path/MATLAB related variables
NUM_PATHS_TO_ADD = 20 # Number of paths to generate at a time
DIM = "[ 900 700 ]"   # The dimension of the test bed as reconstructed by MATLAB
SCALE = "0.1"         # Factor to scale down by for speedy reconstruction
USE_ADAPTIVE = True   # Whether or not to use adaptive path selection
BOUNDS = "[100 120 540 760]" # Bounds on test bed, [x_min, y_min, x_max, y_max]
                             # Has a buffer region to prevent robot from going
                             # off the test bed.

# Robot's Speed
PIXELS_PER_SECOND = 170.0   # Pixels the robot covers in moving straight for 1s
RADS_PER_SECOND = 1.30      # Radians the robot covers in turning for 1s

# Database
dbName = "Log9"  # The database to save to
NO_DATA = -1     # The dummy value to store in database if no data was collected

################################################################################
#                             HTML HANDLERS
################################################################################

# These are essentially for debugging purposes and browser interaction
def htmlForm():
    """
        @brief   Function that generates the html form if a state hasn't been 
                 submitted to the script. 

        @remarks For all practical purposes, this is only when testing
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
        @brief   This function declares that the response will be in json if a
                 state has been submitted to the form.

        @remarks It is separate from jsonResponse() to allow print statements to
                 be added anywhere in the code, as the response header must be
                 declared before any response (through print statements) can be
                 sent.
    """

    print("""Content-type:application/json\n""")


def jsonResponse(response):
    """
        @brief Returns the response in json form.

        @param response   A 3-element list containing
                            0) Response: True or False, depending on whether
                                         the video camrea located the robot
                            1) Duration: How long the robot should turn or
                                         travel along its next path.
                            2) Error Code: Informs whether the locating and
                                           processing of the robot's position
                                           was successful.
    """

    j = {
            'Response': response[0],
            'Duration': response[1],
            'Error Code': response[2]
        }

    print json.dumps(j, indent = 4, separators=(',', ': '))


################################################################################
#                          CAMERA/LOCATION HANDLERS
################################################################################

def locate():
    """
        @brief   Function that uses the overhead video camera to locate robot

        @details The data sent by the robot-tracking script "vehicle_tracker.py"
                 is read from the serial port. The data comes in the following
                 format:
                        *$|x|y|theta|!\\n

        @returns The x, y and theta of the robot

        @remarks The origin of the grid is the bottom-left corner of the test
                 bed, as seen when facing the whiteboard in MS3355.
    """

    ser = serial.Serial(COM_PORT, BAUD_RATE, timeout = SER_TIMEOUT)
    ser.flushInput()
    ser.flushOutput()

    raw_data = ser.readline()

    t = time.time()

    # Read data
    while not raw_data and (time.time() - t < TIMEOUT):
        raw_data = ser.readline()

    if raw_data:
        # Now, begin parsing the data
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
        @brief Given the robot's position and heading, the function returns the
               max time for which the robot can travel before it will go off the
               edge.

        @param x   The x coordinate of the robot
        @param y   The y coordinate of the robot
        @param theta   The heading of the robot

        @returns   The time returned is expected to be the value used by the
                    motors in driving the robot.
    """

    newX = x
    newY = y
    c = 0.5

    while (newX > X_MIN and newX < X_MAX and newY > Y_MIN and newY < Y_MAX):
        newX = x + c * math.cos(theta)
        newY = y + c * math.sin(theta)
        c = c + 0.5

    # return the magnitude, converted to milliseconds
    return int((c - 0.5)/PIXELS_PER_SECOND * 1000)


def findNextTime(startX, startY, theta, endX, endY):
    """
        @brief Function that returns the duration for which the robot should
               move or turn in its subsequent movement to reach a given 
               destination.

        @param startX   The current x-coordinate of the robot
        @param startY   The current y-coordinate of the robot
        @param theta    The current heading of the robot
        @param endX     The next intended x-coordinate for the robot
        @param endY     The next intended y-coordinate for the robot

        @returns   The duration the robot should move/turn for, by calculating
                   the angle or distance to the desired end location, depending
                   on the state of the robot.

        @remark   Whether the robot turns/moves depends on the state it's in.
        @remark   Also, the duration returned can be negative, which means the
                  robot needs to turn right. A positive duration with state 1
                  means the robot needs to turn left.
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
                    int(distanceToTravel/PIXELS_PER_SECOND * 1000))
        else:
            return (int((amountToTurn)/RADS_PER_SECOND * 1000),
                    int(distanceToTravel/PIXELS_PER_SECOND * 1000))


def dotProduct(a, b):
    """
        @brief Helper function - returns dot product of two vectors a and b
    """
    return sum(map( operator.mul, a, b))

def crossProduct(a, b):
    """
        @brief Helper function - returns cross product of two vectors a and b
    """
    c = [a[1]*b[2] - a[2]*b[1],
         a[2]*b[0] - a[0]*b[2],
         a[0]*b[1] - a[1]*b[0]]
    return c
    

################################################################################
#                           MySQL DATABASE HANDLERS
################################################################################

def connectDB(dbName):
    """
        @brief Connects to the database with name 'dbName'

        @returns db and cursor objects.
    """

    db = conn.connect(host = 'localhost', user = 'root', \
                      passwd = 'uclaRobots14', db = dbName)
    cursor = db.cursor()
    return db, cursor


def saveStateToDB(dbName, State, Data, currentX, currentY, theta, destX, destY,\
                  Response, Duration, Error_Code):
    """
        @brief   Stores the state that the robot sent, along with other useful
                 information to keep track of the robot's actions.
        @details Called when the robot has contacted the server, stores info in
                 the debugging table "State_Record".

        @param   dbName   The database to save to
        @param   State    The state the robot submitted to the server
        @param   Data     The data the robot collected and submitted to server
        @param   currentX The x-coord that the video camera returned to server
        @param   currentY The y-coord that the video camera returned to server
        @param   theta    The heading that the video camera returned to server
        @param   destX    The x-coord the robot is trying to get to
        @param   destY    The y-coord the robot is trying to get to
        @param   Response The Response that the server is sending to the robot
        @param   Duration The Duration the robot is sending to the robot
        @param   Error_Code The Error_Code as reported by the server
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
        @brief   Saves the starting coordinates of the robot to the database.
        @details Called when the video camera has located the robot, and the
                 robot is looking to start its path. Saves info to data table
                 "Data_Collection".

        @param dbName   The database to store to
        @param startX   The starting x-coord of the robot
        @param startY   The starting y-coord of the robot

        @remarks   ASSUMES that the previous entry has been completed.
    """

    db, cursor = connectDB(dbName)
    sql = "INSERT INTO Data_Collection(startX, startY) VALUES(" + str(startX) +\
          ", " + str(startY) + ")"
    cursor.execute(sql)
    db.commit()


def saveEndDataToDB(dbName, endX, endY, data, numDataPt):
    """
        @brief   Saves the end coordinates of the robot, along with the data it
                 collected to the database.
        @details Called when the video camera has located the robot and the 
                 robot has completed its path, function saves end coordinates to
                 data table "Data_Collection".

        @param dbName The database to write to
        @param endX   The ending x-coord of the robot
        @param endY   The ending y-coord of the robot
        @param data   The data collected by the robot along this path
        @param numDataPt The entry number in the database to write to
    """

    db, cursor = connectDB(dbName)
    sql = "update Data_Collection set endX = " + str(endX) + ", endY = " + \
          str(endY) + ", data = " + str(data) + " where DataPtID = " + \
          str(numDataPt)
    cursor.execute(sql)
    db.commit()


def numDataCollected(dbName):
    """
        @brief Given the name of the database, returns the number of data points
               collected in the table "Data_Collection".
        @param dbName The database from which to find numDataCollected
        @returns The number of entries in "Data_Collection"
    """

    db, cursor = connectDB(dbName)
    sql = "SELECT COUNT(DataPtID) FROM Data_Collection"
    cursor.execute(sql)
    return cursor.fetchone()[0]


def findCurrentEntry(dbName):
    """
        @brief   Given the name of the database, returns the DataPtID of the
                 most recent entry in the database.
        @param dbName   The database from which to find current entry.
        @returns   The value of DataPtID, the primary key, for the database.

        @remarks  Not always the same as numDataCollected() as there may be
                  insertions or deletions in the database.
    """

    db, cursor = connectDB(dbName)
    sql = "SELECT MAX(DataPtID) FROM Data_Collection"
    cursor.execute(sql)
    return cursor.fetchone()[0]


def inNewLocation(dbName, x, y, currDataEntry):
    """
        @brief   Checks if the given x, y coordinates are outside some radius
                 of the start coordinate of the robot during that data sample,
                 and returns true if so
        
        @param dbName   The database from which to find the last start coords
        @param x        The x-coord of the robot, after it has started its path
        @param y        The y-coord of the robot, after it has started its path
        @param currDataEntry The last entry in the db, used to find start coords

        @returns True if the robot's current position is outside some radius of
                 its start position, false otherwise
    """
    db, cursor = connectDB(dbName)
    sql = "SELECT startX, startY FROM `data_collection` WHERE DataPtID =" + \
          str(currDataEntry)
    cursor.execute(sql)

    result = cursor.fetchone()
    newX = result[0]
    newY = result[1]
    mag = math.sqrt((newX - x)**2 + (newY - y)**2)

    return mag > RADIUS_CUTOFF


################################################################################
#                             MATLAB DATABASE HANDLERS
################################################################################

def getNextDest(dbName, numDataPt, state):
    """
        @brief   Accesses dbName to find the next destination for the robot.

        @details Paths are generated NUM_PATHS_TO_ADD at a time. If all the
                 paths in Next_Paths have been used, genNewDests() is called to
                 generate the next set of paths.

        @param dbName    The db from which to get the next destination
        @param numDataPt The number of data points collected so far, to
                         correctly index the next destination
        @param state     New paths need only be generated once every
                         NUM_PATHS_TO_ADD, and this happens when state = 1.

        @returns The x, y coordinates of the next destination

        @remarks Handles all the communication with MATLAB. None of the other
                 functions in this section need to be called separately.
    """

    if ((numDataPt % NUM_PATHS_TO_ADD) == 0) and (state == 1):
        genNewDests(dbName)

    db, cursor = connectDB(dbName)

    sql = "SELECT x ,y FROM Next_Paths WHERE NextID = " + str(numDataPt + 1)
    cursor.execute(sql)

    x, y = cursor.fetchone()

    return x, y


def genNewDests(dbName):
    """
        @brief   Generate and save the next NUM_PATHS_TO_ADD destinations either
                 randomly or based on previous data, by calling MATLAB's
                 genNextTargets()

        @details This function will add the new list of destinations to
                 existing destinations in Next_Paths. Depending on whether
                 USE_ADAPTIVE is True or False, the call to MATLAB will either
                 ask for adaptive paths or random paths.

        @param dbName   The database to generate new paths in

        @remarks Uses updateNextPaths() to actually update the database and
                 getDataCollected() to read from the database.
    """

    if USE_ADAPTIVE:
        data = getDataCollected(dbName)
    else:
        data = "[]"     # calling MATLAB on empty data will ask for random paths

    numPaths = str(NUM_PATHS_TO_ADD)

    # The call to MATLAB is made here, and only here in the entire script
    matlab = win32com.client.Dispatch('matlab.application')
    matlab.Visible = 0
    matlabQuery = "genNextTargets(" + data + "," + DIM + "," + BOUNDS + "," + \
                                  SCALE +  "," + numPaths + " );"
    newPaths = matlab.Execute(matlabQuery)   # returns MATLAB response as string
    updateNextPaths(dbName, newPaths)
    return 


def updateNextPaths(dbName, newPaths):
    """
        @brief   Adds newPaths to Next_Paths table of database dbName.

        @param dbName   The database to update the next paths in
        @param newPaths A string of the new paths, formatted as "x_0 y_0
                        x_1 y_1 ... x_n y_n", where x_i, y_i is the i'th
                        destination to add.
    """

    db, cursor = connectDB(dbName)
    pathNums = [int(s) for s in newPaths.split() if s.isdigit()]

    # We do not expect pathNums to be odd, because every contiguous pair of
    # numbers Constitutes a coordinate pair.
    for i in range(len(pathNums)/2):
        x = pathNums[2*i]
        y = pathNums[2*i+1]
        
        sql = "INSERT INTO Next_Paths(x, y) VALUES(" + str(x) +\
              ", " + str(y) + ")"
        cursor.execute(sql)

    db.commit()
    return


def getDataCollected(dbName):
    """
        @brief   Given the name of the database, returns the data collected thus
                 far from the table Data_Collection as a string
        @param   dbName   The database from which to pull data
        @returns The startX, startY, endX, endY, Data in Data_Collection get
                 formatted as a MATLAB matrix and returned as a string
    """

    db, cursor = connectDB(dbName)
    sql = "SELECT startX, startY, endX, endY, Data FROM Data_Collection"
    cursor.execute(sql)

    data = "[ "
    for row in cursor:
        data += str(row[0]) + " " + str(row[1]) + " " + str(row[2]) + " " + \
                str(row[3]) + " " + str(row[4]) + "; "
    data += "]"

    return data


################################################################################
#                             MAIN PROGRAM
################################################################################

if __name__ == "__main__":
    try:
        # Find the number of data points collected
        numDataPt = numDataCollected(dbName)

        # Find the current entry in which data is being stored
        currDataEntry = findCurrentEntry(dbName)

        # See if any form data about the has been submitted
        submittedData = cgi.FieldStorage()
        state = submittedData.getvalue("state")

        # If we do know the state, then a successful request has been made
        if state:
            htmlResponse()
            x, y, theta = locate()

            # Parameters that will be logged in the database
            state = int(state)
            data = respX = respY = respTheta = nextX = nextY = NO_DATA
            resp = False
            nextTime = 0
            errorCode = NO_ERROR_T

            if x and y and theta:
                x = int(x)
                y = int(y)
                theta = float(theta)

                # We can log the obtained coordinates in the database
                respX = x
                respY = y
                respTheta = theta

                # Perform checks and calculations to figure out whether i) the
                # robot has been located ii) how much time it should move for
                # iii) the error code to send
                if state == 0:
                    nextX, nextY = getNextDest(dbName, numDataPt, state)
                    _, timeToTravel = findNextTime(x, y, theta, nextX, nextY)

                    # maxTime = findMaxTime(x, y, theta)
                    # Check whether the robot can actually move 'timeToTravel'
                    # to the next point, and respond appropriately. The reason
                    # the robot might have to travel for just maxTime instead of
                    # timeToTravel is that it might not have changed its heading
                    # very accurately.
                    # if maxTime < timeToTravel:
                    #     respX = x
                    #     respY = y
                    #     respTheta = theta
                    #     resp = True
                    #     nextTime = maxTime
                    #     errorCode = NO_ERROR_M
                    # else:
                    #     nextTime = random.randint(MIN_TIME_TO_TRAVEL, maxTime)

                    resp = True
                    nextTime = timeToTravel
                    errorCode = NO_ERROR_T
                    saveStartToDB(dbName, respX, respY)

                elif state == 1:
                    data = int(submittedData.getvalue("data"))

                    # Check whether the camera has recognized that the robot has
                    # moved to a new location -- there is some lag between the
                    # robot moving and the camera locating it.
                    if not currDataEntry or \
                                     inNewLocation(dbName, x, y, currDataEntry):
                        nextX, nextY = getNextDest(dbName, numDataPt, state)
                        timeToTurn, _ = findNextTime(x, y, theta, nextX, nextY)

                        resp = True
                        nextTime = timeToTurn                    
                        errorCode = NO_ERROR_T
                        if currDataEntry:
                            saveEndDataToDB(dbName, x, y, data, currDataEntry)

                    else:
                        errorCode = NNL_ERROR

            # If the robot has sent a request but it has not been located,
            # respond to let it know not to move.
            else:
            	errorCode = S_TIMEOUT_ERROR

            # Record this activity in the database and respond to the arduino
            saveStateToDB(dbName, state, data, respX, respY, respTheta, \
                          nextX, nextY, resp, nextTime, errorCode)
            jsonResponse([resp, nextTime, errorCode])

        # This is for the human-reader case, when no state has been submitted.
        else:
            htmlForm()

    except:
        cgi.print_exception()

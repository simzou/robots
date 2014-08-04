#!C:\Python27\python.exe

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
sys.path.append("C:\Python27\Lib\site-packages")

import mysql.connector as conn
import time
import math
import operator
import random
import json
import serial

## Path Directions for the Robot


target = [(171, 476), (302, 750), (136, 150), (165, 578), (304, 284), (472, 579), (214, 287), (107, 638), (463, 197), (415, 508), (469, 151), (191, 700), (322, 175), (106, 468), (496, 150), (191, 239), (258, 548), (368, 130), (220, 423), (428, 176), (128, 349), (462, 433), (157, 557), (535, 536), (334, 759), (118, 342), (396, 746), (281, 196), (402, 577), (255, 226), (217, 755), (146, 144), (518, 183), (498, 623), (457, 325), (425, 667), (337, 143), (410, 517), (248, 178), (434, 699), (515, 170), (179, 245), (480, 480), (509, 168), (339, 623), (128, 314), (539, 700), (240, 396), (483, 649), (324, 214), (165, 583), (344, 298), (452, 732), (409, 261), (206, 520), (300, 190), (152, 739), (343, 242), (124, 463), (318, 696), (135, 247), (525, 328), (119, 326), (415, 175), (110, 707), (417, 123), (119, 738), (223, 180), (392, 580), (143, 242), (331, 516), (505, 252), (485, 581), (196, 341), (344, 703), (246, 416), (473, 681), (145, 392), (397, 558), (107, 212), (455, 710), (140, 231), (497, 684), (186, 434), (459, 688), (273, 328), (406, 601), (167, 138), (368, 444), (156, 146), (465, 471), (152, 216), (352, 593), (314, 234), (155, 659), (397, 374), (531, 658), (216, 159), (385, 630), (163, 163), (170, 636), (501, 200), (216, 335), (516, 350), (210, 527), (476, 377), (164, 650), (500, 512), (267, 190), (391, 624), (276, 321), (475, 686), (103, 186), (401, 317), (317, 622), (506, 175), (101, 574), (326, 347), (398, 746), (152, 398), (493, 406), (191, 553), (538, 347), (206, 681), (465, 527), (295, 143), (209, 523), (319, 138), (539, 703), (453, 152), (523, 584), (316, 214), (312, 667), (285, 312), (195, 691), (506, 610), (200, 351), (238, 685), (165, 126), (232, 660), (474, 248), (467, 731), (182, 448), (427, 665), (428, 225), (260, 663), (370, 217), (468, 605), (511, 181), (483, 751), (396, 365), (142, 196), (454, 326), (528, 648), (236, 325), (331, 736), (353, 157), (161, 699), (166, 351), (469, 710), (123, 214), (219, 524), (514, 436), (282, 707), (400, 369), (320, 677), (494, 365), (151, 601), (530, 542), (152, 628), (165, 169), (129, 706), (215, 349), (119, 675), (385, 159), (418, 523), (439, 148), (334, 451), (446, 155), (340, 609), (529, 134), (322, 495), (524, 158), (453, 453), (168, 608), (143, 195), (526, 145), (259, 338), (534, 657), (113, 657), (505, 674), (297, 414), (248, 727), (485, 504), (158, 304), (431, 148), (512, 619), (196, 157), (186, 486), (441, 679), (302, 178), (345, 580), (535, 259), (195, 704), (501, 133), (174, 744), (227, 285), (323, 756), (114, 441), (485, 687), (109, 240), (527, 602), (454, 231), (137, 730), (534, 496), (177, 296), (500, 354), (106, 328), (214, 754), (467, 188), (197, 652), (124, 263), (427, 203), (339, 640), (254, 307), (525, 644)]

# target = [(357, 444), (214, 290), (125, 600), (237, 338), (483, 603), (202, 485), (222, 186), (228, 580), (279, 596), (473, 727), (234, 396), (474, 241), (321, 237), (500, 133), (503, 516), (323, 329), (295, 605), (496, 473), (140, 255), (104, 466), (315, 658), (470, 485), (515, 280), (491, 394), (127, 182), (459, 171), (122, 577), (373, 528), (326, 226), (333, 326), (130, 261), (533, 551), (216, 157), (402, 625), (424, 236), (454, 394), (116, 238), (510, 270), (347, 627), (261, 219), (377, 343), (117, 198), (494, 518), (130, 566), (239, 714), (105, 610), (282, 496), (236, 263), (505, 657), (471, 567), (430, 243), (514, 330), (174, 742), (391, 615), (423, 681), (506, 457), (491, 641), (259, 619), (385, 532), (204, 234), (465, 275), (465, 235), (497, 304), (375, 595), (391, 302), (522, 373), (170, 284), (528, 645), (109, 328), (309, 139), (158, 138), (348, 476), (437, 231), (167, 496), (340, 591), (235, 580), (480, 289), (465, 440), (127, 333), (322, 724), (305, 416), (255, 742), (304, 393), (249, 739), (236, 335), (435, 481), (423, 713), (262, 378), (468, 121), (411, 381), (497, 718), (249, 467), (270, 715), (528, 609), (186, 157), (158, 530), (480, 287), (362, 519), (221, 721), (463, 458), (228, 604), (200, 328), (229, 430), (144, 712), (240, 479), (223, 386), (182, 637), (510, 616), (528, 696), (500, 545), (222, 146), (401, 576), (220, 224), (167, 205), (226, 177), (520, 419), (492, 661), (365, 480), (352, 614), (243, 187), (423, 723), (458, 198), (343, 310), (404, 747), (385, 555), (231, 518), (295, 259), (442, 747), (119, 594), (410, 486), (532, 722), (160, 361), (166, 193), (527, 354), (183, 330), (427, 231), (414, 209), (109, 494), (336, 746), (326, 589), (258, 229), (289, 160), (175, 394), (158, 281), (122, 262), (108, 182), (280, 390), (215, 253), (537, 407), (283, 752), (479, 639), (473, 215), (187, 505), (364, 707), (477, 392), (265, 548), (246, 717), (170, 286), (148, 210), (374, 120), (245, 551), (183, 612), (213, 166), (307, 148), (377, 579), (422, 367), (126, 354), (270, 149), (462, 407), (203, 566), (327, 209), (352, 560), (277, 631), (527, 687), (190, 120), (180, 424), (258, 120), (492, 593), (353, 504), (496, 186)]


# target = [
#             (81, 476),
#             (307, 712),
#             (492, 263),
#             (58,  544),
#             (222, 628),
#             (400, 139),
#             (200, 252),
#             (430, 673),
#             (172, 401),
#             (316, 629),
#             (45, 138)
#          ]
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

PIXELS_PER_SECOND = 150.0   # Pixels the robot covers in moving straight for 1s
RADS_PER_SECOND = 1.25      # Radians the robot covers in turning for 1s

RADIUS_CUTOFF = 75   # The minimum radius the robot needs to be from its start
                     # before its new position is registered

MIN_TIME_TO_TRAVEL = 1500  # The minimum time the robot will travel in any path

dbName = "Log5"  # The database to save to

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

    ser = serial.Serial('COM6', 115200, timeout=2, xonxoff=False,
                                                     rtscts=False, dsrdtr=False)
    ser.flushInput()
    ser.flushOutput()

    raw_data = ser.readline()

    ser.flushInput()
    ser.flushOutput()

    raw_data = ser.readline()

    ser.flushInput()
    ser.flushOutput()

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
        loopIndex = len(raw_data)/2

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
    return int((c - 0.5)/PIXELS_PER_SECOND * 1000)


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
                    int(distanceToTravel/PIXELS_PER_SECOND * 1000))
        else:
            return (int((amountToTurn)/RADS_PER_SECOND * 1000),
                    int(distanceToTravel/PIXELS_PER_SECOND * 1000))


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


def findCurrentEntry(dbName):
    """
        Given the name of the database, returns the DataPtID of the most recent
        entry in the database. DataPtID is the primary key for the database.
    """

    db, cursor = connectDB(dbName)
    sql = "SELECT MAX(DataPtID) FROM Data_Collection"
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
            data = respX = respY = respTheta = NO_DATA
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
                    _, timeToTravel = findNextTime(x, y, theta, 
                                  target[numDataPt % numTargets][0],
                                  target[numDataPt % numTargets][1])

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
                    if inNewLocation(dbName, x, y, currDataEntry):
                        timeToTurn, _ = findNextTime(x, y, theta,
                                        target[numDataPt % numTargets][0],
                                        target[numDataPt % numTargets][1])

                        resp = True
                        nextTime = timeToTurn                    
                        errorCode = NO_ERROR_T
                        saveEndDataToDB(dbName, x, y, data, currDataEntry)

                    else:
                        errorCode = NNL_ERROR

            # If the robot has sent a request but it has not been located,
            # respond to let it know not to move.
            else:
            	errorCode = S_TIMEOUT_ERROR

            # Reocrd this activity in the database and respond to the arduino
            saveStateToDB(dbName, state, data, respX, respY, respTheta, \
            			  target[numDataPt % numTargets][0],            \
                          target[numDataPt % numTargets][1],            \
                          resp, nextTime, errorCode)
            jsonResponse([resp, nextTime, errorCode])

        # This is for the human-reader case, when no state has been submitted.
        else:
            htmlForm()

    except:
        cgi.print_exception()

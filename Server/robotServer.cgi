#!/usr/local/bin/python2.7

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

import mysql.connector as conn
import time
import json


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

                        <input type = "submit" name = "submitdata" value = "Submit" />
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
            'Response': response[0]
        }

    print json.dumps(j, indent = 4, separators=(',', ': '))


################################################################################
#                             CAMERA HANDLERS
################################################################################


def locate():
    """
        Function that returns the x and y coordinates of the robot if it has
        been detected, and None and None otherwise.
    """

    ## TODO! -- Write this function.

    return 2, 3



# def saveState(state):
#     currentTime = time.ctime(time.time())
#     stateObject = {currentTime : state}
#     filename = "Log1.json"
#     path = 'Logs/' + filename

#     f = open(path, 'a')
#     f.write("    " + currentTime + " : " + str(state) + "\n")
#     #json.dump(stateObject, f, indent=4)
#     f.close()

#     print "Saved state to file ", filename, "\n"


################################################################################
#                             MySQL DATABASE HANDLERS
################################################################################


def connectDB(dbName):
    """
        Connects to the database with name 'dbName'
    """

    db = conn.connect(host = 'localhost', user = 'root', \
                      passwd = '19*geroniMO', db = dbName)
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
        to the database
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


################################################################################
#                             MAIN PROGRAM
################################################################################


if __name__ == "__main__":
    try:       
        # The database to save to
        dbName = "Log1"

        # The number of data points collected
        numDataPt = numDataCollected(dbName)

        # See if any form data about the has been submitted
        submittedData = cgi.FieldStorage()
        state = submittedData.getvalue("state")

        # If we do know the state, then Arduino has made a successful request
        if state:                          # state is a string here, not bool
            htmlResponse()

            state = int(state)
            saveStateToDB(dbName, state)   # Record the state in the database
        
            x, y = locate()

            # If the camera has located the Arduino
            if x and y:
                # Save its position to the database, along with data if it has
                # been collected, and let the robot know.
                if state == 0:
                    saveStartToDB(dbName, x, y)
                    jsonResponse([True])

                elif state == 1:
                    data = int(submittedData.getvalue("data"))
                    saveEndDataToDB(dbName, x, y, data, numDataPt)
                    jsonResponse([True])

                else:
                    print "Error: Unknown State"

            # If the robot has sent a request but it has not been located,
            # respond to let it know not to move.
            else:
                jsonResponse([False])

        # This is for the human-reader case, when no state has been submitted.
        else:
            htmlForm()

    except:
        cgi.print_exception()

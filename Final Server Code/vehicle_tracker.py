#!C:\Python27\python.exe

## @package vehicle_tracker
## @author Siddarth Srinivasan (UCLA REU 2014)
## @date 4th August 2014
## @brief   Python Script that uses the overhead video camera to track a single
#           robot with a black-and-white tag on the test bed.
## @remarks The origin of the grid is originally at the top left corner, with x
#           increasing across and y increasing downward, but the origin has been
#           artificially transformed to the bottom left corner. Similarly, the
#           positive angle was defined clockwise, but has been transformed to
#           counter clockwise. Left and right refer to the test bed as seen when
#           facing the whiteboard in MS3355.

import time
import math
import cv2
import serial

# Threshold Constants
CAM_THRESHOLD = 90      # All pixels under this will be assigned black      
COLOUR_MAX = 255        # All pixels above this value will be assigned black

# Control the Exposure of the images: Acceptable values range from -10.0 to -8.0
# where -10.0 is darker than -8.0. -8.0 makes the image look brighter than it
# really is, but makes tracking easier.
EXPOSURE = -8.0

RESET = 500                # How many iterations to reset the camera in

# RGB Colours, used for drawing rectangles
PURPLE = (255, 0, 255)
GREEN = (0, 255, 0)
WHITE = (255, 255, 255)

# Differences in the position of Camera 1 with respect to Camera 0
X_OFFSET = 12
Y_OFFSET = 412

# Coordinate Transformation Constants
Y_ORIGIN_SHIFT = 480        # Y-dimension of the image, used to shift origin
THETA_SHIFT = 2 * math.pi   # To make angles increase counter clockwise

# Tag and Header Pixel Sizes
MIN_TAG_AREA = 280
MAX_TAG_AREA = 1200
MIN_HEADER_AREA = 35
MAX_HEADER_AREA = 168

# Global Variable to keep track of whether the robot has been located
hasFoundRobot = False

# Serial Port to which location data will be sent
COM_PORT = 'COM1'
BAUD_RATE = 115200
SER_TIMEOUT = 2

################################################################################
#                          VIDEO PROCESSING FUNCTIONS
################################################################################

def camProcessing(filtered, CAM):
    """
        @brief   Find contours and locate the robot
        @details Takes in a thresholded image, locates the robot along with
                 header strip and returns the location and heading of the robot.
        @param filtered   A filtered image
        @param CAM        The camera number - 0 or 1 - for the two camera Setup

        @returns The x-coordinate, y-coordinate and heading of the robot.
    """

    global hasFoundRobot
    
    # Setup array for sorting the rectangles
    tagContours = []      # Array storing tag-sized contours
    tagCenters = []       # Array storing centers of the tag-sized contours
    foundCarIndex = 0     # Index to track tagContour corresponding to robot

    headerContours = []   # Array storing header-sized contours
    headerCenters = []    # Array storing centers of header-sized contours
    foundHeadingIndex = 0 # Index to track headerContour corresponding to robot

    # Create a CvSequence of all the contours and store in 'contour'
    contours, _ = cv2.findContours(filtered, cv2.RETR_LIST, 
                                   cv2.CHAIN_APPROX_NONE)

    ##--------------------------------------------------------------------------
    ## Loop over all contours to locate tag and header strip
    ##--------------------------------------------------------------------------

    for c in contours:
        # Get a rectangle around a contour
        x, y, width, height = cv2.boundingRect(c)
        current = [x, y, width, height]
        area = height * width

        # Check the area of the bounding rectangle to see if it fits within the 
        # thresholds for tag or header rectangles.
        if ((area >= MIN_TAG_AREA) and (area <= MAX_TAG_AREA)): 
            tagContours += [current]
            tagCenters += [ (x + width/2, y + height/2) ]
            continue
           
       
        if ((area >= MIN_HEADER_AREA) and (area <= MAX_HEADER_AREA)):
            headerContours += [current]
            headerCenters += [(x + width/2, \
                               y + height/2)]
            continue


    ##--------------------------------------------------------------------------
    ## Find the headerContour that fits inside a tagContour in the same
    ## approximate position -- that will be where the robot is and the other
    ## rectangles can be discarded.
    ##--------------------------------------------------------------------------

    foundCarIndex = 0

    ## Draw the tag-sized contours
    for t in tagContours:
        tag_x = t[0]
        tag_y = t[1]
        tag_w = t[2]
        tag_h = t[3]
        cv2.rectangle(filtered, (tag_x, tag_y), (tag_x + tag_w, tag_y + tag_h),\
                      WHITE, 1)
    

    ## For each tagContour, check if there is a headerContour that fits inside.
    ## If so, the robot has been located.
    for i in range(len(tagContours)):
        for j in range(len(headerContours)):
            if headerFitsInTag(tagContours[i], headerContours[j]):
                foundCarIndex = i
                foundHeadingIndex = j
                if (CAM == 0):
                    hasFoundRobot = True
                
                cv2.rectangle(filtered, (headerContours[j][0], \
                            headerContours[j][1]), (headerContours[j][0]  + \
                            headerContours[j][2], headerContours[j][1] + \
                            headerContours[j][3]), WHITE, 1)

                break    ## break from inner for loop
        
    ##--------------------------------------------------------------------------
    ## Retrieve data to be sent
    ##--------------------------------------------------------------------------

    if (CAM == 0) and tagCenters and headerCenters:
        xCoord = tagCenters[foundCarIndex][0]
        yCoord = Y_ORIGIN_SHIFT - tagCenters[foundCarIndex][1]
        theta = getHeading(tagCenters[foundCarIndex],
                       headerCenters[foundHeadingIndex]) 
        print "x: ", xCoord, " y:", yCoord, " theta: ", theta, " Cam: ", CAM
        sendData(xCoord, yCoord, theta)
    
    elif ((CAM == 1) and (not hasFoundRobot)) and tagCenters and headerCenters:
        xCoord = tagCenters[foundCarIndex][0] + X_OFFSET
        yCoord = Y_ORIGIN_SHIFT - tagCenters[foundCarIndex][1] + Y_OFFSET
        theta = getHeading(tagCenters[foundCarIndex],
                       headerCenters[foundHeadingIndex]) 
        print "x: ", xCoord, " y:", yCoord, " theta: ", theta, " Cam: ", CAM
        sendData(xCoord, yCoord, theta)   


def headerFitsInTag(tag, header):
    """
        @brief   Checks if the given header fits inside the given tag.

        @param tag  A 4-element list containing x, y, width, height of a tag
                    sized contour
        @param header A 4-element list containing x, y, width, height of a
                      header sized contour

        @returns   True if the header fits inside the tag, False otherwise
    """

    tag_x = tag[0]
    tag_y = tag[1]
    tag_w = tag[2]
    tag_h = tag[3]

    header_x = header[0]
    header_y = header[1]
    header_w = header[2]
    header_h = header[3]

    if ((header_x < tag_x) or (header_y < tag_y)):
        return 0
    if ((header_x - tag_x > tag_w) or (header_y - tag_y > tag_h)):
        return 0

    return 1


def getHeading(tag, header):
    """
        @brief  Finds the heading of the robot given the coordinates of the tag
                and header strip.
        @details Draws a vector from the tag's center to the header's center to
                 find the heading of the robot.

        @param tag    A 2-element list containing the (x,y) coordinates of the
                      tag's center
        @param header A 2-element list containing the (x,y) coordinates of the
                      header's center

        @returns  The heading of the robot, in the range 0 to 2*pi.
    """

    tag_x  = tag[0]
    tag_y  = tag[1]
    head_x = header[0]
    head_y = header[1]

    xhat = float(head_x - tag_x)
    yhat = float(head_y - tag_y)

    theta = math.atan2(yhat, xhat)
    
    if (theta < 0):
        theta = theta + (2 * math.pi)

    return THETA_SHIFT - theta


def camSetup():
    cam0 = cv2.VideoCapture(0)
    cam1 = cv2.VideoCapture(1)
    cam0.set(cv2.cv.CV_CAP_PROP_EXPOSURE, EXPOSURE)
    cam1.set(cv2.cv.CV_CAP_PROP_EXPOSURE, EXPOSURE)

    if not cam0.isOpened() or not cam1.isOpened():
        print "Cannot open one or both camera(s)"
        return None, None

    return cam0, cam1


def camRelease(cam0, cam1):
    # When everything is done, release the capture
    cam0.release()
    cam1.release()
    cv2.destroyAllWindows()



################################################################################
#                           MISCELLANEOUS FUNCTIONS
################################################################################

def sendData(xCoord, yCoord, theta):
    """
        @brief  Sends the location and heading of the robot over serial

        @param xCoord  The x-coordinate of the robot to be sent
        @param yCoord  The y-coordinate of the robot to be sent
        @param theta   The heading of the robot to be sent
    """
    ser = serial.Serial(COM_PORT, BAUD_RATE, timeout = SER_TIMEOUT)
    ser.flushInput()
    ser.flushOutput()

    data = "*$|" + str(xCoord) + "|" + str(yCoord) + "|" + str(theta) + "|!\n"
    ser.write(data)
    ser.close()


def findYOriginShift(cam):
    """
        @brief  Returns the y-dimension of the image, used to verify
                Y_ORIGIN_SHIFT
    """

    _, image = cam.retrieve()
    return image.shape[0]


################################################################################
#                             MAIN PROGRAM
################################################################################

def main():

    global hasFoundRobot
    resetCounter = 0
    ## Set up video camera and set exposure
    cam0, cam1 = camSetup()
    if not cam0 or not cam1:
        return

    while(True):
        resetCounter += 1
        # Capture frame-by-frame
        ret0, frame0 = cam0.read()
        ret1, frame1 = cam1.read()

        # Our operations on the frame come here
        img0 = cv2.cvtColor(frame0, cv2.COLOR_BGR2GRAY)
        img1 = cv2.cvtColor(frame1, cv2.COLOR_BGR2GRAY)

        # Filter the images and process them
        retv0, filtered0 = cv2.threshold(img0, CAM_THRESHOLD, COLOUR_MAX, 
                                         cv2.ADAPTIVE_THRESH_MEAN_C)
        retv1, filtered1 = cv2.threshold(img1, CAM_THRESHOLD, COLOUR_MAX,
                                         cv2.ADAPTIVE_THRESH_MEAN_C)

        camProcessing(filtered0, 0)
        camProcessing(filtered1, 1)
        hasFoundRobot = False
        
        # Display the images
        cv2.imshow('cam0',img0)
        cv2.imshow('cam1', img1)
        cv2.imshow('filtered0', filtered0)
        cv2.imshow('filtered1', filtered1)

        # Reset the image from the camera every RESET iterations. This is a
        # hacky fix for the shifting image issue (see Readme).
        if resetCounter == RESET:
            camRelease(cam0, cam1)
            cam0, cam1 = camSetup()
            resetCounter = 0
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    camRelease(cam0, cam1)

if __name__ == '__main__':
    main()
    

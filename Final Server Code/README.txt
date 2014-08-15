FILE: README.txt
AUTHOR: Siddarth Srinivasan (UCLA REU 2014)
DATE: 11th August 2014


Contents
--------

I.    Introduction
II.   Applications Needed to Run this Project
III.  Libraries
IV.   Drivers
V.    Code Documentation
VI.   Arduino Pins
VII.  Hardware on Robot
VIII. Other Hardware
IX.   Setup
X.    Run
XI.   Other Issues
XII.  Future Improvements


I. Introduction
---------------
This file details all the applications, libraries and drivers needed to ensure
the project runs smoothly, and provides instructions to set up and run the
project. Full code documentation can be found at:
		C:\REU_2014_Server\Documentation\html\index.html
"The project" refers to the "Environental Mapping by Autonomous Robots Using
Compressed Sensing" project completed by the UCLA Computational and Applied Math
REU 2014 Team consisting of M. Horning, S. Zou, S. Srinivasan and M. Lin.

At the time of writing, all project files are in C:\REU_Server_2014 on
MUFASA-PC. See setup-server below on what is affected when changes are made.


II. Applications Needed to Run this Project
-------------------------------------------
1) XAMPP: to set up Apache server and MySQL database
2) Arduino IDE: to upload programs to the robot and view output on Terminal
3) Python 2.7: to run vehicle_tracker.py and the server cgi script
4) MATLAB: to carry out the image reconstruction


III. Libraries
--------------
1) Arduino Libraries:
	*   AdaFruit WiFi Shield Library: to enable the arduino to connect to
	  wireless networks.
	*   Arduino Json Library: so that the Arduino can parse the response from
	  the server.

2) Python Libraries:
	*   OpenCV: to use the camera to track the robot on the testbed.
	*   PySerial: to read and write Serial Data to COM ports
	*   MySQL connector: to enable python to perform SQL commands with databases
	*   PythonWin: to enable python to commmunicate with MATLAB


IV. Drivers
-----------
1) Prolific 2303 Serial Driver: To recognize the USB-Serial cable
	http://www.prolific.com.tw/US/ShowProduct.aspx?p_id=229&pcid=4
2) Generic 1394 Camera Driver: To recognize the overhead cameras on Firewire
	http://www.driverscape.com/download/generic-1394-desktop-camera


V. Code Documentation
---------------------
1) Accessing Documentation/html/index.html should show you the doxygen generated
  documentation for the project. THE CGI SCRIPTS HAD TO HAVE THEIR EXTENSIONS
  CHANGED TO .PY BEFORE DOXYGEN COULD BE RUN, SO KEEP THAT IN MIND. 
2) Doxywizard can be run from cmd to configure the doxygen output, or edit and
 run doxygen doxygen from C:\REU_2014_Server.
3) The .cgi and .py scripts are documented under "Packages" and the .ino file is
  documented under "Files"


VI. Arduino Pins
----------------
1) The pins used by the WiFi Shield can be found at:
	https://learn.adafruit.com/adafruit-cc3000-wifi/connections
2) Digital Pins 6-9 are used to control the motor.
3) Analog Pin 4 is connected to the reflectance sensor.


VII. Hardware on Robot
----------------------
1) Arduino Uno
		http://arduino.cc/en/Main/arduinoBoardUno
   with AdaFruit WiFi Shield
   		http://www.adafruit.com/products/1491

2) NEOMART L298N Motor Controller:
		https://s3.amazonaws.com/tontec/l298n.zip

3) DFRobot 4WD Chassis with 4 motors:
  		http://www.amazon.com/DFRobot-Pirate-4wd-Mobile-Platform/dp/B009646R3K/ref=sr_1_cc_2?s=aps&ie=UTF8&qid=1408062128&sr=1-2-catcorr&keywords=dfrobot+4wd

4) Rectangular white tag with black boundary and black header strip

5) 5x 1.5V AA Battery to power motors
		http://www.amazon.com/AmazonBasics-Precharged-Rechargeable-Batteries-16-Pack/dp/B007B9NV8Q/ref=sr_1_2?ie=UTF8&qid=1408062203&sr=8-2&keywords=amazon+batteries+aa

6) 9V EBL battery to power Arduino
		http://www.amazon.com/EBL%C2%AE-Battery-Charger-Rechargeable-Batteries/dp/B00HV4KFSA/ref=sr_1_1?ie=UTF8&qid=1408062243&sr=8-1&keywords=9v+rechargeable+ebl


VIII. Other Hardware
--------------------
1) USB to Serial Cable (Use Prolific 2303 Driver):
		http://www.adafruit.com/blog/wp-content/uploads/2011/01/usbserial_MED.jpg

2) Serial Cable:
		http://www.homanndesigns.com/store/images/DB9F-DB9M_Serial_cable.jpg

3) Two Wi232 Transceivers: Download configuration tool from here
		http://mikrokopter.de/ucwiki/RadioTronix#Download_Konfigurationstool
   It has currently been installed on this computer. It is used to test the 
   Wi232 transceivers, and set the channel on which the transmit and receive. To
   configure (it should already be configured, so you wouldn't normally need to
   do this):

   		a) Switch the jumper on the Wi232 while the transceiver is still on.
   			When the jumper is on the two pins towards the red LED and away from
   			the switch, it is in "USE" mode.
   			When the jumper is on the two pins close to the switch and away from
   			the LED, it is in "DEBUG" mode.
   			IMPORTANT: DO NOT SWITCH OFF AND SWITCH ON THE TRANSCEIVER WHEN THE
   			JUMPER IS IN THIS "DEBUG" MODE, IT WILL RESET THE CHANNELS TO
   			DEFAULT.
   		b) Open "Radiotronix Wi.232DTS Evaluation", select the COM port and the
   		   Baud Rate (should be 115200) and click on "Discover module".
   		c) Click on "Read" on the Transmit Channel and Receive Channel, and note
   		   down the channel.
   		d) Move the jumper back to "USE" mode.
   		e) Do the same thing with the other transceiver, and check that the
   		   transmission channel of each transceiver matches the receiving
   		   channel of the other transceiver.

4) TP-LINK Router: Used to broadcast the private network on which the server
				   will be hosted. To configure, connect to the computer by
				   ethernet and go to 192.168.0.1 and enter user: admin and
				   password: admin.


IX. Setup
---------
1) Cameras:
	*   Ensure that the two cameras are plugged into the FireWire ports.
	*   Check Device Manager -> Imaging Devices to make sure the drivers are
	  installed and working properly.
	*   Ensure that the USB-Serial cable is plugged in and connected to the
	  Wi232 transceiver, and the COM_PORT in vehicle_tracker.py matches the COM
	  port that shows up in Device Manager. This is the COM port that the
	  overhead camera will write to.
	*   Also ensure that the transceiver is powered on.
	*   You should be able to run vehicle_tracker.py.
	*   vehicle_tracker.py will quit and restart every so often. (Refer to 
	  known issues).
	*	ONLY QUIT vehicle_tracker.py by pressing 'q'. Otherwise, you may get an
		error (see Known Issues) the next time you try to run it.

2) Server:
	*   Launch XAMPP and start Apache and MySQL.
	*   Check that in the file Apache -> Config -> httpd.conf (as accessed from
	  XAMPP), the DocumentRoot and Directory in Line 242-243 are set to the
	  folder containing the server files. At the time of writing, it is set to
	  "C:\REU_2014_Server". If this is changed, the Arduino will also have to
	  change its request (see Robot).
	*   The server files are robotServer.cgi and databaseManager.cgi. Both can
	  be accessed at C:\REU_2014_Server\.
	*   Login to localhost/phpmyadmin with user: root and password: uclaRobots14
	  to access the databases.
	*   Goto localhost/databaseManager.cgi to create, clear or delete databases.
	*   Ensure that the serial cable is connected to the Wi232 transceiver, and
	  the transceiver is powered on.
	*   Also ensure that the COM_PORT in robotServer.cgi matches the COM port
	  that shows up in Device Manager. This is the COM port to read robot's
	  position from.
	*   Check that dbName in robotServer.cgi matches the name of the database
	  you wish to access.
	*   Test localhost/robotServer.cgi by entering states 0 or 1 (other states
	  will not work, and state 1 requires data submission) and checking the
	  database at localhost/phpmyadmin for changes in State_Record.
	*   You will want to clear the database after testing.
	*   'State_Record' keeps track of all communications with the server,
		'Data_Collection' is the final data table and 'Next_Paths' is the SQL
		table storing the next set of paths.

3) Robot:
	*   Launch Arduino IDE, connect the Arduino to the computer and check that
	  it has been detected on Tools -> Serial Port.
	*   Use and modify motor_ir_test.ino in Miscellaneous to calibrate
	  PIXELS_PER_SECOND and RADS_PER_SECOND. Run vehicle_tracker.py and observe
	  change in x or y as the robot moves vertically or horizontally for 1
	  second for PIXELS_PER_SECOND and change in theta as the robot rotates for
	  1 second for RADS_PER_SECOND.
	*   Use ir_test.ino to verify MAX_SENSOR and WHITE_BOUNDARY by placing the
	  reflectance sensor of black and white regions on the test bed.
	*   The file for robot logic is compressedSensing.ino.
	*	Check that the WLAN_SSID, WLAN_PASS, WLAN_SECURITY, IP, Port and 
	  repository in compressedSensiong.ino match the network you wish to use.
	  ipconfig on cmd will give you the ip-address of the network the server is
	  on.
	*   Ensure the chassis is covered with black tape, so that the camera
	  doesn't confuse some part of the chassis for the tag.
	*   Upload compressedSensing.ino to the Arduino.


X. Run
------
1) Launch vehicle_tracker.py.
2) Launch XAMPP and start Apache and MySQL.
3) Place the Arduino on the test bed and connect the board to the battery.


XI. Known Issues
----------------
1) Off the test bed: Occasionally, the video camera might make a mistake and
  					 accidentally send the robot off the test bed. If that
  					 happens, put the robot back on the test bed and ignore
  					 that data point.
2) Select Video Source: If vehicle_tracker.py is not quit properly, the next
						time it is run, it may ask you to select a video source,
						but still give you trouble. To solve this, open Task
						Manager and end pythonw.exe that takes around 30,000 K.
						If this still doesn't work, end all the pythonw.exe
						processes and run vehicle_tracker.py again.
3) Cannot open a camera: Unplug and replug in the firewire connections. Also
						 check the Device Manager. For some reason, checking
						 Device Manager makes it work again. 
4) Shifting image: The video displayed by vehicle_tracker.py unpredictably gets
 				   shifted sometimes. Unknown reason, but if that happens,
 				   restart vehicle_tracker.py. Current fix includes restarting
 				   the camera every RESET number of iterations.
5) Parallax: The tag is not exactly centered at the reflectance sensor, and may
			 cause some noise in the data.


XII. Future Improvements
------------------------
1) Eliminate the need for the Wi232 transceivers by creating virtual ports or
  sockets, so that the server-side script can communicate with
  vehicle_tracker.py without external hardware.
2) Write small test programs for the individual libraries.
3) Extend the analog sensor for use with images with varying shades of grey.
  Currently, a reading from the reflectance sensor is characterised as black or
  white based on the reading. Add more 'buckets' based on the range of values.
4) Write a script that can access the 'State_Record' and display the current
  status of the robot. This will save time from trying to make sense of the
  status data in 'State_Record'.

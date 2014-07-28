Download XAMPP, start it

System Preferences -> Network -> Advanced -> TCP/IP
	Note IPv4 address

Access ip from another computer: 
	Error: New Xampp security concept

Goto XAMPP/etc/extra/httpd-xampp.conf (as specified in error)
	At bottom of file, replace "Require local" to "Require all granted"

Go to security tab in xampp homepage
	If things are unsecure, run the instructed
	sudo /Applications/XAMPP/xamppfiles/xampp security

	xampp pages: xampp/uclaRobots14
	phpMyAdmin: pma/uclaRobots14
	mySQL: root/uclaRobots14
	proFTPD: daemon/uclaRobots14

Put	robotServer.cgi, databaseManager.cgi, and compressedSensing in htdocs
	Make sure path points to python

	install mysql-connector-python

	pip install --allow-external mysql-connector-python \
  mysql-connector-python


pyserial
prolific 2303
import serial
ser = serial.Serial('/dev/tty.PL2303-00001014', 115200, timeout=2)

PL2303 driver caused keyboard and mouse to freeze

Found reference to problem here: http://networkingnerd.net/2013/01/04/mountain-lion-pl-2303-driver-crash-fix/

which links to this: 
http://www.xbsd.nl/2011/07/pl2303-serial-usb-on-osx-lion.html

	$ cd /path/to/osx-pl2303.kext
	$ sudo cp -R osx-pl2303.kext /System/Library/Extensions/

next you need to fix permissions and execute bits:

	$ cd /System/Library/Extensions
	$ sudo chmod -R 755 osx-pl2303.kext
	$ sudo chown -R root:wheel osx-pl2303.kext
	$ cd /System/Library/Extensions
	$ sudo kextload ./osx-pl2303.kext
	$ sudo kextcache -system-cache

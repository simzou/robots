/**
 * \file compressedSensing.ino
 * \authors Siddarth Srinivasan (UCLA REU 2014)
 * \date 10th July 2014
 *
 * \brief Arduino code to collect and communicate data to a server which can
 *   reconstruct it using a compressed sensing algorithm.
 */

// Include required libraries
#include <Adafruit_CC3000.h>
#include <ccspi.h>
#include <SPI.h>
#include <string.h>
#include "utility/debug.h"
#include <JsonParser.h>
using namespace ArduinoJson::Parser;

// Define the interrupt and control pins for AdaFruit, and other Arduino pins
#define ADAFRUIT_CC3000_IRQ   3 
#define ADAFRUIT_CC3000_VBAT  5
#define ADAFRUIT_CC3000_CS    10
#define IR 9
#define LED 13

// WiFi Network Username/Pwd/Security
#define WLAN_SSID       "UCLA-MATHNET"
#define WLAN_PASS       ""
#define WLAN_SECURITY   WLAN_SEC_WEP

// Memory to allocate for the char array that stores the  server response
#define PREALLOC 512

// Number of paths to travel on, also equal to number of data points
#define NUM_PATHS 3

// Instantiate the AdaFruit WiFi shield object and the client object
Adafruit_CC3000 cc3000 = Adafruit_CC3000(ADAFRUIT_CC3000_CS, 
                                         ADAFRUIT_CC3000_IRQ,
                                         ADAFRUIT_CC3000_VBAT,
                                         SPI_CLOCK_DIVIDER);
Adafruit_CC3000_Client client;

// Variables for connecting to the network and server
uint32_t ip = cc3000.IP2U32(169,232,149,167);
int port = 93;
String repository = "/projects/Robots14/";

// Connection Timeout Variable
const unsigned long connectTimeout = 15L * 100L;

// Variables specific to the robot's functioning
bool state = false;             // Will be 0 or 1, refer to robotServer.cgi
bool oldState = false;          // Stores the state before update
uint16_t data = 0;              // The summed reflectance sensor readings
uint16_t paths = 0;             // The number of measurements taken

// Objects to parse the Json Response
JsonParser<8> parser;
JsonHashTable root;


/*******************************************************************************
 *                        SETUP AND LOOP FUNCTIONS                             *
 ******************************************************************************/

/**
 * \brief The required setup function for the Arduino
 * \details Initializes the pins on the Arduino and sets up an internet
 *          connection.
 */
void setup(void)
{
    Serial.begin(9600);
    pinMode(IR, INPUT);
    pinMode(LED, OUTPUT);
    setupConnection();
}


/**
 * \brief The required loop function for the Arduino
 * \details Handles the main logic for the Arduino. Essentially, it checks if
 *          the Arduino has travelled NUM_PATHS. If not, check how its state has
 *          changed: 
 *              1) If it has gone from state 0 to state 1, it is ready to move
 *                 and collect data from the reflectance sensor.
 *              2) If it has gone from state 1 to state 0, it is ready to move
 *                 to a new starting position.
 *              3) Otherwise, the state has not changed, so the server has not
 *                 been able to successfully locate the robot, so send a request
 *                 to the server again.
 */
void loop(void)
{
    if (paths < NUM_PATHS) {

        String request = "GET " + repository + "robotServer.cgi?state=" +
                 state + "&data=" + data + "&submitdata=Submit" + 
                 " HTTP/1.1\r\n" + "Host: " + ip + ":" + port + "\r\n";

        // Record the state before sending the request
        oldState = state;
        if (send_request(request)) {
            get_response();
        }

        if ((oldState == 1) && (state == 0)) {
            // We have just travelled a path and data needs to be reset
            ++paths;
            data = 0;
            // moveToNewStart()
        }
        else if ((oldState == 0) && (state == 1)){
            Serial.println("Collecting Data");
            digitalWrite(LED, HIGH);
            for (uint16_t i = 0; i < 50000 ; ++i )
                data += digitalRead(IR);
            digitalWrite(LED, LOW);
        }
    }
    else if (paths == NUM_PATHS) {
        // Clean up the connection
        Serial.println(F("\n\nClosing the connection"));
        cc3000.disconnect();
        ++paths;
    }  
}


/*******************************************************************************
 *                           HELPER FUNCTIONS                                  *
 ******************************************************************************/

/**
 * \brief Sends a request to the server with the state and possibly data
 * \details Connects to the server at 'ip' through 'port' using TCP, for as long
 *          as the connection does not timeout. If successfully connected, send
 *          a HTTP request to the page in the 'request' string with state and
 *          data.
 *
 * \param request   The HTTP request that is sent to the server.
 *
 * \returns         true if the request is made successfully, false otherwise
 */
bool send_request (String request)
{
    Serial.print("Connecting to server...");
    int t = millis();
    do {
        client = cc3000.connectTCP(ip, port);
    } while ((!client.connected()) && ((millis() - t) < connectTimeout));

    // Send request
    if (client.connected()) {
      Serial.print(F("OK\r\nIssuing HTTP request..."));
      client.println(request);      
      client.println(F(""));
      Serial.println("Connected & Sent data");
      return true;
    } 
    else {
      Serial.println(F("Connection failed"));
      return false;
    }
}


/**
 * \brief Receives and processes the HTTP response from the server
 * \details The response from the server gets stored in responseHTTP, but it
 *          also gets parsed to obtain just the json response without the
 *          headers in responseJSON. If the server's 'Response' is true, then
 *          it has identified the robot's location, so we can flip its state.
 *
 * \remarks The parsing code was taken from
 *              http://forum.arduino.cc/index.php/topic,188902.0.html
 *          It works under the assumption that there is no nesting in the json
 *          file. IT WILL NOT WORK FOR ALL JSON RESPONSES.
 */
void get_response() {

    Serial.println("\nGetting response");

    // Counters and Arrays to store the response
    static uint16_t resHIndex = 0;
    static uint16_t resJIndex = 0;
    char responseHTTP[PREALLOC];    // Will store entire response, with headers
    char responseJSON[PREALLOC];    // Will store parsed JSON response
    bool readingJson = false;

    // Read the response into the arrays
    while (client.connected()) {
        while (client.available()) {
            // Read response and store in responseHTTP and responseJSON
            char inChar = client.read();
            responseHTTP[resHIndex++] = inChar;
    
            if(inChar == '{') {
                readingJson = true;
            }
            if(readingJson) {
                responseJSON[resJIndex++] = inChar; // Store it

                if(inChar == '}') {
                    readingJson = false; 
                }
            }
        }
    }

    // C strings must have the '\0' terminating character
    responseHTTP[resHIndex] = '\0';
    responseJSON[resJIndex] = '\0';

    for (int i = 0; i < resJIndex; ++i) {
      Serial.print(responseJSON[i]);
    }

    resHIndex = 0;
    resJIndex = 0;

    Serial.println("");
    Serial.println("Closing connection to server and parsing response...");
    client.close();

    root = parser.parseHashTable(responseJSON);
    if (root.getBool("Response")) {
        state = !state;
    }
}


/*******************************************************************************
 *                  ADAFRUIT SHIELD CONNECTIVITY FUNCTIONS                     *
 ******************************************************************************/

/**
 * \brief Starts up the AdaFruit CC3000 Shield and connects to the internet
 * \details Prints the amount of free RAM, checks initialization of the WiFi
 *          shield, deletes old connection profiles and obtains an IP address.
 *
 * \remarks The following code was taken from AdaFruit's buildTest example.
 */
void setupConnection(void)
{
    Serial.println(F("Hello, CC3000!\n")); 
    Serial.print("Free RAM: "); 
    Serial.println(getFreeRam(), DEC);
    
    // Initialise the module
    Serial.println(F("\nInitialising the CC3000..."));
    if (!cc3000.begin()) {
        Serial.println(F("Unable to initialise CC3000! Check your wiring."));
        while(1);
    }

    // Delete any old connection data on the module
    Serial.println(F("\nDeleting old connection profiles"));
    if (!cc3000.deleteProfiles()) {
      Serial.println(F("Failed!"));
      while(1);
    }

    // Attempt to connect to an access point
    char *ssid = WLAN_SSID;                 // Max 32 chars
    Serial.print(F("\nAttempting to connect to ")); Serial.println(ssid); 

    if (!cc3000.connectToAP(WLAN_SSID, WLAN_PASS, WLAN_SECURITY)) {
      Serial.println(F("Failed!"));
      while(1);
    }
    Serial.println(F("Connected!"));
    
    // Wait for DHCP to complete
    Serial.println(F("Request DHCP"));
    while (!cc3000.checkDHCP())
    {
      //delay(100); // ToDo: Insert a DHCP timeout!
    }  

    /* Display the IP address DNS, Gateway, etc. */  
    while (!displayConnectionDetails()) {
      //delay(1000);
    }
}


/**
 * \brief Retrieves the IP address and other connection details.
 * \details Prints the IP Address, Netmask, Gateway, DHCP server and DNS server.
 *
 * \remarks The following code was taken from AdaFruit's buildTest example.
 */
bool displayConnectionDetails(void)
{
    uint32_t ipAddress, netmask, gateway, dhcpserv, dnsserv;
    
    if(!cc3000.getIPAddress(&ipAddress, &netmask, &gateway, 
                            &dhcpserv, &dnsserv)) {
      Serial.println(F("Unable to retrieve the IP Address!\r\n"));
      return false;
    }
    else {
      Serial.print(F("\nIP Addr: ")); cc3000.printIPdotsRev(ipAddress);
      Serial.print(F("\nNetmask: ")); cc3000.printIPdotsRev(netmask);
      Serial.print(F("\nGateway: ")); cc3000.printIPdotsRev(gateway);
      Serial.print(F("\nDHCPsrv: ")); cc3000.printIPdotsRev(dhcpserv);
      Serial.print(F("\nDNSserv: ")); cc3000.printIPdotsRev(dnsserv);
      Serial.println();
      return true;
    }
}

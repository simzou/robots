/**
 * Author: Siddarth Srinivasan
 * Date: 10th July 2014
 *
 */

// Include required libraries
#include <Adafruit_CC3000.h>
#include <ccspi.h>
#include <SPI.h>
#include <string.h>
#include "utility/debug.h"

// Parsing the response from the server
#include <JsonParser.h>
using namespace ArduinoJson::Parser;

// Define the interrupt and control pins
#define ADAFRUIT_CC3000_IRQ   3 
#define ADAFRUIT_CC3000_VBAT  5
#define ADAFRUIT_CC3000_CS    10

// WiFi Network Username/Pwd/Security
#define WLAN_SSID       "UCLA-MATHNET"
#define WLAN_PASS       "5Dog+8Cat<Ape"
#define WLAN_SECURITY   WLAN_SEC_WEP

// Memory to allocate for the char array that stores the response
#define PREALLOC 4608

// Number of paths to travel on, also equal to number of data points
#define NUM_PATHS 6

// Instantiate the AdaFruit WiFi shield object and the client
Adafruit_CC3000 cc3000 = Adafruit_CC3000(ADAFRUIT_CC3000_CS, 
                                         ADAFRUIT_CC3000_IRQ,
                                         ADAFRUIT_CC3000_VBAT,
                                         SPI_CLOCK_DIVIDER);

Adafruit_CC3000_Client client;

// Variables for connecting to the network and server
uint32_t ip = cc3000.IP2U32(169,232,149,138);
int port = 93;
String repository = "/projects/Robots14/";

// Connection Timeout Variable
const unsigned long connectTimeout = 15L * 100L;

// Variables specific to the robot's functioning
bool state = false;             // Will be 0 or 1, refer to comments FIXME!
bool oldState = false;
uint16_t data = 0;              // The summed reflectance sensor readings
uint16_t paths = 0;             // The number of measurements taken

// Parse Response
JsonParser<16> parser;
JsonHashTable root;


/**************************************************************************/
/*!
    @brief  Sets up the HW and the CC3000 module (called automatically
            on startup)
*/
/**************************************************************************/
void setup(void)
{

    Serial.begin(115200);
    setupConnection();

 
}

void loop(void)
{
    if (paths < NUM_PATHS) {

        // Depending on how the state has changed
        if ((oldState == 1) && (state == 0)) {
            ++paths;
        }
        else if ((oldState == 0) && (state == 1)){

        }
        
        String request = "GET " + repository + "robotServer.cgi?state=" +
                     state + "&data=" + data + "&submitdata=Submit" + 
                     " HTTP/1.1\r\n" + "Host: " + ip + ":" + port + "\r\n";

        oldState = state;
        if (send_request(request)) {
            get_response();
        }




        Serial.println(paths);
    }
    else if (paths == NUM_PATHS) {
    
        // Clean up the connection
        Serial.println(F("\n\nClosing the connection"));
        cc3000.disconnect();
        ++paths;
    }

    
}

// Function to send a TCP request and get the result as a string
bool send_request (String request) {
    
    // Connect to the server
    Serial.println("Connecting to server...");
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


void get_response() {

    Serial.println("Getting response...");

    // Counters and Arrays to store the response
    static uint16_t resHIndex = 0;
    static uint16_t resJIndex = 0;
    char responseHTTP[PREALLOC];    // Will store entire response, with headers
    char responseJSON[PREALLOC];    // Will store parsed JSON response
    bool readingJson = false;


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

    // Parse the response
    root = parser.parseHashTable(responseJSON);
    if (root.getBool("Response")) {
        state = !state;
    }
    
}




/**************************************************************************/
/*!
    @brief  Takes care of the setup

    @note 
*/
/**************************************************************************/
void setupConnection(void)
{
    Serial.println(F("Hello, CC3000!\n")); 
    Serial.print("Free RAM: "); 
    Serial.println(getFreeRam(), DEC);
    
    // Initialise the module
    Serial.println(F("\nInitialising the CC3000 ..."));
    if (!cc3000.begin())
    {
      Serial.println(F("Unable to initialise the CC3000! Check your wiring?"));
      while(1);
    }

    
    /* Delete any old connection data on the module */
    Serial.println(F("\nDeleting old connection profiles"));
    if (!cc3000.deleteProfiles()) {
      Serial.println(F("Failed!"));
      while(1);
    }

    /* Attempt to connect to an access point */
    char *ssid = WLAN_SSID;             /* Max 32 chars */
    Serial.print(F("\nAttempting to connect to ")); Serial.println(ssid); 
    /* NOTE: Secure connections are not available in 'Tiny' mode!
       By default connectToAP will retry indefinitely, however you can pass an
       optional maximum number of retries (greater than zero) as the fourth 
       parameter.
    */
    if (!cc3000.connectToAP(WLAN_SSID, WLAN_PASS, WLAN_SECURITY)) {
      Serial.println(F("Failed!"));
      while(1);
    }
    Serial.println(F("Connected!"));

    
    /* Wait for DHCP to complete */
    Serial.println(F("Request DHCP"));
    while (!cc3000.checkDHCP())
    {
      delay(100); // ToDo: Insert a DHCP timeout!
    }  

    /* Display the IP address DNS, Gateway, etc. */  
    while (! displayConnectionDetails()) {
      delay(1000);
    }

}


/**************************************************************************/
/*!
    @brief  Tries to read the IP address and other connection details
*/
/**************************************************************************/
bool displayConnectionDetails(void)
{
    uint32_t ipAddress, netmask, gateway, dhcpserv, dnsserv;
    
    if(!cc3000.getIPAddress(&ipAddress, &netmask, &gateway, &dhcpserv, &dnsserv))
    {
      Serial.println(F("Unable to retrieve the IP Address!\r\n"));
      return false;
    }
    else
    {
      Serial.print(F("\nIP Addr: ")); cc3000.printIPdotsRev(ipAddress);
      Serial.print(F("\nNetmask: ")); cc3000.printIPdotsRev(netmask);
      Serial.print(F("\nGateway: ")); cc3000.printIPdotsRev(gateway);
      Serial.print(F("\nDHCPsrv: ")); cc3000.printIPdotsRev(dhcpserv);
      Serial.print(F("\nDNSserv: ")); cc3000.printIPdotsRev(dnsserv);
      Serial.println();
      return true;
    }
}



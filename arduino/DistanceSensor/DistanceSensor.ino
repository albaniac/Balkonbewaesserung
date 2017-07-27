#include <Wire.h>

/**
 * The MySensors Arduino library handles the wireless radio link and protocol
 * between your home built sensors/actuators and HA controller of choice.
 * The sensors forms a self healing radio network with optional repeaters. Each
 * repeater and gateway builds a routing tables in EEPROM which keeps track of the
 * network topology allowing messages to be routed to nodes.
 *
 * Created by Henrik Ekblad <henrik.ekblad@mysensors.org>
 * Copyright (C) 2013-2015 Sensnology AB
 * Full contributor list: https://github.com/mysensors/Arduino/graphs/contributors
 *
 * Documentation: http://www.mysensors.org
 * Support Forum: http://forum.mysensors.org
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 *
 *******************************
 *
 * REVISION HISTORY
 * Version 1.0 - Henrik EKblad
 * 
 * DESCRIPTION
 * This sketch provides an example how to implement a distance sensor using HC-SR04 
 * http://www.mysensors.org/build/distance
 */

// Enable debug prints
#define MY_DEBUG

// Enable and select radio type attached
#define MY_RADIO_NRF24
//#define MY_RF24_PA_LEVEL RF24_PA_LOW
//#define MY_RADIO_RFM69

#include <SPI.h>
#include <MySensors.h>  
#include <NewPing.h>

#define CHILD_ID 13
#define TRIGGER_PIN  6  // Arduino pin tied to trigger pin on the ultrasonic sensor.
#define ECHO_PIN     5  // Arduino pin tied to echo pin on the ultrasonic sensor.
#define MAX_DISTANCE 300 // Maximum distance we want to ping for (in centimeters). Maximum sensor distance is rated at 400-500cm.
unsigned long SLEEP_TIME = 3000; // Calculate every 10 seconds

#define MY_RF24_CE_PIN 9
#define MY_RF24_CS_PIN 10

NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE); // NewPing setup of pins and maximum distance.
MyMessage msg(CHILD_ID, V_DISTANCE);
int lastDist;
bool metric = true;

void setup()  
{ 
  metric = getControllerConfig().isMetric;
}

void presentation() {
  // Send the sketch version information to the gateway and Controller
  sendSketchInfo("Distance Sensor", "1.1");

  // Register all sensors to gw (they will be created as child devices)
  present(CHILD_ID, S_DISTANCE);
}

void loop()      
{     
  // Ping 5 times and calculate median
  int dist_ms = sonar.ping_median(5);
  // Calculate actual distance
  int dist = metric?sonar.convert_cm(dist_ms):sonar.convert_in(dist_ms);
  Serial.print("Ping: ");
  Serial.print(dist); // Convert ping time to distance in cm and print result (0 = outside set distance range)
  Serial.println(metric?" cm":" in");

  if (dist != lastDist) {
      send(msg.set(dist));
      lastDist = dist;
  }

  sleep(SLEEP_TIME);
}



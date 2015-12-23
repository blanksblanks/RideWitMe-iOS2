# RideWitMe-iOS

## A Team
An interactive route planner on iOS and web with recommendations for the best possible Citibike route based on station, traffic, terrain conditions and insider tips from real users. Plan a trip with your friends and see their locations updated in realtime as you converge on your destination.

#### Main View - ViewController.swift
##### viewDidAppear
 * Sets up gpaViewController  (Google Places Autocomplete) and pops up with search bar over the map, where table row elements beneath the search bar give user's suggested location results.
##### viewDidLoad
 * Set up customized Map from MapView and Location Manager. For first time user and only once, pops up with alert notification asking for authorization to monitor user location activities real time.
##### updateMapFrame, mapview(mapView: MGLMapView, … etc.) functions
 * various mapView functions to customize and generally use the delegate pattern to receive notifications when events happen like user taps and subsequently update the map.

##### getDirections ()
 * UI Alert View that gives user the option to input in two text fields the addresses of the starting and ending locations. User input in the text fields are autocompleted via Google Places  and  they also forward the latitude and longitude details for any of the user's selected locations.
getAllStations ()
GET request to endpoint
 * Endpoint: "http://www.citibikenyc.com/stations/json"
 * UI Update: Markers annotate all over New York City and surrounding boroughs as well as New Jersey. Currently all default markers; (plan to have yellow markers for stations with 30%-70% bike to docks ratio, red for any stations with less than 30% of its bikes, and  green for any stations with more than 70% of its bikes available, with details to pop up when tapped.)
getClosestPoints (latA: Double, lngA: Double, latB: Double, lngB: Double)
 * Params to the function are the coordinates of the user's start and end locations
 * POST NSDictionary in request to endpoint
 * Endpoint: http://ridewitme.elasticbeanstalk.com/getClosestPoints
 * Request: ```["srclat": "",
 * "srclng": "",
 * "destlat": "",
 * "destLng": ""]```
 * Response:  See RideWitMe README for detailed response from the API. Most relevant details for purposes of this app are (latitude, longitude) of nearest start and end stations
 * UI Update: Markers for two closest bike station coordinates pop up on the page. Map marker details contain the coordinates and the title start or end. Calls the getRoutes method subsequently on these new station start and end's two pairs of coordinate points subsequently.
##### getRoutes (latA: Double, lngA: Double, latB: Double, lngB: Double)
 * Params to the function are the coordinates of the start and end station locations
 * Post NSDictionary in request to endpoint
Endpoint: http://ridewitme.elasticbeanstalk.com/getRoutes
Request: ```["srclat": "",
 * "srclng": "",
 * "destlat": "",
 * "destLng": ""]```
 * Response:  See RideWitMe README for detailed response from the API. Our app currently reads the routes response objects for the top three routes, distances, durations for each route (to find the minimum) as well as all the points in the route to draw the polyline. Currently the route is a single color; (plan to color routes by red for incline, yellow for relatively flat, green for decline, by analyzing the difference of elevation figures associated with each coordinate in the route.)
 * UI Update: Use MapBox to annotate Map View with a polyline for suggested route. Currently only shows the best route by the criteria of least duration, distance and elevation; (plan to show 1-3 best routes and allow users to tap the other routes for different suggestions). The route currently has a time and distance as its title; plan to annotate with more information.
##### shareLocation
 * UI Alert View that gives user the option to input a Group name and Password to share location with friends
##### createGroup (groupTitle: String, password: String?)
 * Creates a group by unique group name and password
insertTableRow (tableRow: DDBTableRow)
 * Inserts newly created group in Dynamo table
##### updateLocation (tableRow: DDBTableRow, lat:Double, log:Double)
 * Updates the group's member's nearest coordinates every three seconds in the relevant table row indicated by the groupID
##### locationManager (manager: CLLocationManager, didUpdateLocations locations:[CLLocation])
* Tracks the current user's location, adding it every 3 seconds if there is a change, and draws his/her route on the map. Also tracks direction and velocity. Currently always on if user gives permission for app to user Location Services; (plan to allow user to toggle it on and off).
##### extension ViewController: GooglePlacesAutocompleteDelegate
 * Sets up a subclassed view controller to act as delegate to respond to new notifications for autocomplete.

#### Google Places Autocomplete.swift
Contains methods to use Google Places API to autocomplete user-filled forms. Open source class from @watsonbox on GitHub. Can access places by their names, longitude and latitude, as well as other details exposed by the Google Places API.

#### Group Table View Controller.swift
Efficient Table View  that lists the current user's legal groups and allows users to tap any of the group names to see detail and map of current group member.

#### Group Location View Controller.swift
Queries DynamoDB for the correct group member and current location in the map and updates the map view with the group member's changing route.

#### DDBDynamoDBManager.swift
Sets up AWS DynamoDB table with Group ID as the hash key schema element, Group Title as the range key schema element, other  relevant non-key  attributes such as password, longitude, latitude. Also set up global secondary index where the range key array is a list of password, latitude, longitude, and gsi array of the changing secondary indices. Also formats any calls to the mapper to format any data to be input to the table as table input.

#### Constants.swift
Sets up constants using Cognito to set up AWS.

#### citiBike-Bridging-Header.h
Note this is the only .h file, the rest are .swift files. Imports the relevant Objective-C libraries and dependencies for use.

#### App Delegate.swift
Starting point of the app - autogenerated with XCode project and customized with our AWS configurations.

## System Dependencies / Pods / Etc.
Development Environment:
Swift 2.0
XCode 7.0
iOS 8.3+ (supports up to 9.0, need XCode 7.1 beta for up to 9.2 support)
CocoaPods:
Using AWSCore (2.2.7)
Using AWSDynamoDB (2.2.7)
Using AWSCognito (2.2.7)
Using Mapbox-iOS-SDK (3.0.0)
Using PubNub (3.7.2)
Swift imports:
import UIKit
import CoreLocation
import Foundation
import MapKit
Objective-C imports:
```
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "PNImports.h"
#import "MapBox.h"
#import <AWSDynamoDB/AWSDynamoDB.h>
```
Endpoints:
 * Google Places API:  "https://maps.googleapis.com/maps/api/place/autocomplete/json",
* RideWitMe API: "http://ridewitme.elasticbeanstalk.com"
* CitiBike live station feed: "http://www.citibikenyc.com/stations/json"

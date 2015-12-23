//
//  ViewController.swift
//  citiBike
//
//  Created by 吴梦宇 on 12/5/15.
//  Copyright (c) 2015 ___mengyu wu___. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {

//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//
//        let gpaViewController = GooglePlacesAutocomplete(
//            apiKey: "AIzaSyAh9WkG-N-PSAxo6zl_AyBdQePN54PIO-0",
//            placeType: .Address
//        )
//
//        gpaViewController.placeDelegate = self
//
//        presentViewController(gpaViewController, animated: true, completion: nil)
//        
//        
//    }
    
    var mapView: MGLMapView!
    var manager: CLLocationManager!

    private var myLocations = [CLLocation]()
    private var currentPositionAnnotation = MGLPointAnnotation()
    private var currentLocation = CLLocation()
    private var polylineAnnotation = MGLPointAnnotation()
    private var isFirstMessage = true

    var label = UILabel(frame: CGRectMake(0, 0, 300, 21))
    
    var groupTitleField: UITextField?
    var passwordField:UITextField?
    var locationInfo:DDBTableRow?
    
    //find directions button
    @IBAction func findDirections(sender: AnyObject) {
        print("find directions button pressed")
        //getAllStations()
        getClosestPoints(40.7127, lngA: -74.0059, latB: 40.7256, lngB: -74.0156)
    }
    
    
    //share location button
    @IBAction func shareLocation(sender: AnyObject) {
        print("share my location button pressed")
        let alert = UIAlertController(title: "Share Location", message: "Create A Group", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler(groupNameTextField)
        alert.addTextFieldWithConfigurationHandler(passwordTextField)
        // Create the actions
    
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            NSLog("OK Pressed")
            
            if let title=self.groupTitleField?.text{
              self.createGroup(title, password: self.passwordField?.text)
            } else {
                print("Please enter group name!")
            }
           
           
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            NSLog("Cancel Pressed")
        }
        
        // Add the actions
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func createGroup(groupTitle: String, password: String?) {
        let groupTableRow = DDBTableRow()
        groupTableRow!.GroupTitle = groupTitle
        groupTableRow!.GroupId = groupTitle
        if let pwd = password {
            groupTableRow!.Password = pwd
        } else {
            groupTableRow!.Password = ""
        }
        self.insertTableRow(groupTableRow!)
    }
    
    func insertTableRow(tableRow: DDBTableRow) {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
        dynamoDBObjectMapper.save(tableRow) .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
            if (task.error == nil) {
                let alertController = UIAlertController(title: "Succeeded", message: "Successfully inserted the data into the table.", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel) { UIAlertAction-> Void in
                }
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
                self.locationInfo=tableRow
                
            } else {
                print("Error: \(task.error)", terminator: "")
                
                let alertController = UIAlertController(title: "Failed to insert the data into the table.", message: task.error.description, preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel){ UIAlertAction -> Void in
                }
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            
            return nil
        })
    }
    
    func updateLocation(tableRow: DDBTableRow, lat:Double, log:Double){
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        print("update group:\(tableRow.GroupId)")
        tableRow.Lat=lat
        tableRow.Log=log
        
        dynamoDBObjectMapper .save(tableRow) .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
            if (task.error == nil) {
                print("update Success")
              
            } else {
                print("Error: \(task.error)", terminator: "")
                
                let alertController = UIAlertController(title: "Failed to update the data into the table.", message: task.error.description, preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel){UIAlertAction -> Void in
                }
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            
            return nil
        })

    }
    
    func groupNameTextField(textField: UITextField!){
        // add the text field and make the result global
        textField.placeholder = "GroupName"
        groupTitleField=textField
        
    }
    
    func passwordTextField(textField: UITextField!){
        // add the text field and make the result global
        textField.placeholder = "Password"
        passwordField=textField
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        // Setup location manager
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        
        
        // Do additional setup after loading the view, typically from a nib.
        myLocations.removeAll(keepCapacity: false)
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        // Set the map's center coordinate to New York, New York
        mapView.setCenterCoordinate(CLLocationCoordinate2D(latitude: 40.7326808,
            longitude: -73.9843407),
            zoomLevel: 12, animated: false)
        
        // Set the delegate property of our map view to self after instantiating it
        mapView.delegate=self
        mapView.showsUserLocation=true
        mapView.addSubview(label)
        view.addSubview(mapView)
        
        label.center = CGPointMake(160, 300)
        label.textAlignment = NSTextAlignment.Center
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        myLocations.append(locations[0] )
        
        if (myLocations.count > 1) {
            let sourceIndex = myLocations.count - 1
            let destinationIndex = myLocations.count - 2
            
            let c1 = myLocations[sourceIndex].coordinate
            let c2 = myLocations[destinationIndex].coordinate
            var a = [c1, c2]
            
            self.currentLocation=myLocations[destinationIndex]
            print("\(self.currentLocation.coordinate.latitude)  \(self.currentLocation.coordinate.longitude)")
            let latLabel=Double(round(self.currentLocation.coordinate.latitude*100)/100)
            let logLabel=Double(round(self.currentLocation.coordinate.longitude*100)/100)
            let lat=Double(self.currentLocation.coordinate.latitude)
            let log=Double(self.currentLocation.coordinate.longitude)
            let speed=Int(self.currentLocation.speed)
            label.text="lat:\(latLabel) log:\(logLabel) speed:\(speed)"
            if let tableRow=self.locationInfo{
                 print("update location")
                 updateLocation(tableRow, lat:lat, log:log)
            }
           
            let polyline = MGLPolyline(coordinates: &a, count: UInt(a.count))
            mapView.addAnnotation(polyline)
            self.updateMapFrame()
        }
    }
    
    func getAllStations() {
        let postEndpoint: String = "http://www.citibikenyc.com/stations/json"
        guard let url = NSURL(string: postEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = NSURLRequest(URL: url)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        let task = session.dataTaskWithRequest(urlRequest, completionHandler: {
            (data, response, error) in
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            guard error == nil else {
                print("error calling GET on /posts/1")
                print(error)
                return
            }
            // parse the result as JSON, since that's what the API provides
            let post: NSDictionary
            do {
                post = try NSJSONSerialization.JSONObjectWithData(responseData,
                    options: []) as! NSDictionary
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
            // now we have the post, let's just print it to prove we can access it
            print("The post is: " + post.description)
            if let stationList = post["stationBeanList"] as? NSArray {
                for station in stationList {
                    let latitude = (station["latitude"] as! NSNumber).doubleValue
                    let longitude = (station["longitude"] as! NSNumber).doubleValue
                    //                    print(latitude, ", ", longitude)
                    self.addMarker(latitude, lng: longitude, bikes: 1, docks: 1)
                }
            }
        })
        task.resume()
    }
    
    func addMarker(lat: Double, lng: Double) {
        // Declare the marker `hello` and set its coordinates, title, and subtitle
        let hello = MGLPointAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        hello.title = "Latitude:\(lat)"
        hello.subtitle = "Longitude:\(lng)"
        // Add marker `hello` to the map
        mapView.addAnnotation(hello)
    }
    
    func addMarker(lat: Double, lng: Double, bikes: Double, docks: Double) {
        // Declare the marker `hello` and set its coordinates, title, and subtitle
        let hello = MGLPointAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        hello.title = "Hello world!"
        hello.subtitle = "Welcome to my marker"
        // Add marker `hello` to the map
        mapView.addAnnotation(hello)
        
    }
    
    func markClosestPoints(latA: Double, lngA: Double, latB: Double, lngB: Double) {
        addMarker(latA, lng: lngA)
        print("\(latA), \(lngA)")
        addMarker(latB, lng: lngB)
        print("\(latB), \(lngB)")
    }
    
    func getClosestPoints(latA: Double, lngA: Double, latB: Double, lngB: Double) {
        //get latitude and long and then post to /getClosestPoints()
//        let postsEndpoint: String = "http://ridewithme-routing.elasticbeanstalk.com/getClosestPoints"
        let postsEndpoint: String = "http://f9c6aa14.ngrok.io/getClosestPoints"
        guard let postsURL = NSURL(string: postsEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        let postsUrlRequest = NSMutableURLRequest(URL: postsURL)
        postsUrlRequest.HTTPMethod = "POST"
        
        let stringPost = "srclat=\(latA)&srclng=\(lngA)&destlat=\(latB)&destlng=\(lngB)"
        let data = stringPost.dataUsingEncoding(NSUTF8StringEncoding)
        postsUrlRequest.HTTPBody = data
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        var nearestSourceLat = 0.0
        var nearestSourceLong = 0.0
        var nearestDestLat = 0.0
        var nearestDestLong = 0.0
        
        let task = session.dataTaskWithRequest(postsUrlRequest, completionHandler: {
            (data, response, error) in
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            guard error == nil else {
                print("error calling POST")
                print(error)
                return
            }
            
            // parse the result as JSON, since that's what the API provides
            let post: NSDictionary
            do {
                post = try NSJSONSerialization.JSONObjectWithData(responseData, options: []) as! NSDictionary
            } catch  {
                print("error trying to convert response data")
                return
            }

            nearestSourceLat = ((post["nearestSrcPoint"] as! NSArray)[0] as! NSNumber).doubleValue
            nearestSourceLong = ((post["nearestSrcPoint"] as! NSArray)[1] as! NSNumber).doubleValue
            
            nearestDestLat = ((post["nearestDestPoint"] as! NSArray)[0] as! NSNumber).doubleValue
            nearestDestLong = ((post["nearestDestPoint"] as! NSArray)[1] as! NSNumber).doubleValue

            //            print("The post is: " + post.description)
            print(nearestSourceLat)
            print(nearestSourceLong)
            print(nearestDestLat)
            print(nearestDestLong)
            
            self.addMarker(nearestSourceLat, lng: nearestSourceLong)
            self.addMarker(nearestDestLat, lng: nearestDestLong)

            // Get routes for nearest points
            self.getRoutes(nearestSourceLat, lngA: nearestSourceLong, latB: nearestDestLat, lngB: nearestDestLong)

            })
        
            task.resume()
        }
    
    
        func getRoutes(latA: Double, lngA: Double, latB: Double, lngB: Double) {
            /* get the nearest source and dest points and pass to the /getRoutes */
//            let postsEndpoint: String = "http://ridewithme-routing.elasticbeanstalk.com/getRoutes"
            

            let postsEndpoint: String = "http://f9c6aa14.ngrok.io/getRoutes"
            guard let postsURL = NSURL(string: postsEndpoint) else {
                print("Error: cannot create URL")
                return
            }
            
            let postsUrlRequest = NSMutableURLRequest(URL: postsURL)
            postsUrlRequest.HTTPMethod = "POST"

                // Post request
                let stringPost = "srclat=\(latA)&srclng=\(lngA)&destlat=\(latB)&destlng=\(lngB)"
                let data = stringPost.dataUsingEncoding(NSUTF8StringEncoding)
                postsUrlRequest.HTTPBody = data

                let config = NSURLSessionConfiguration.defaultSessionConfiguration()
                let session = NSURLSession(configuration: config)

                // Read response
                let task = session.dataTaskWithRequest(postsUrlRequest, completionHandler: {
                    (data, response, error) in
                    print(response)
                    guard let responseData = data else {
                        print("Error: did not receive data")
                        return
                    }
                    guard error == nil else {
                        print("error calling POST")
                        print(error)
                        return
                    }
                
                    // parse the result as JSON, since that's what the API provides
                    let post: NSDictionary
                    do {
                        post = try NSJSONSerialization.JSONObjectWithData(responseData,
                            options: []) as! NSDictionary
                    } catch  {
                        print("error trying to convert data to JSON")
                        return
                    }
                                print("The post is: " + post.description)
                
                    /* find the min distance  */
                    var min_dist = (((post["routes"] as! NSArray)[0] as! NSDictionary)["distance"] as! NSNumber).intValue
                
                    for (object) in (post["routes"] as! NSArray) {
                        if ((object["distance"] as! NSNumber).intValue < min_dist) {
                            min_dist = (object["distance"] as! NSNumber).intValue
                        }
                    }
                
                    /* find min duration */
                    var min_duration = (((post["routes"] as! NSArray)[0] as! NSDictionary)["duration"] as! NSNumber).intValue
                
                    for (object) in (post["routes"] as! NSArray) {
                        if ((object["duration"] as! NSNumber).intValue < min_duration) {
                            min_duration = (object["duration"] as! NSNumber).intValue
                        }
                    }
                
                })
            
            task.resume()
            
            /* Use min distance and duration and Surface details; sum three thing - just select the first route */
        }
    
    func updateMapFrame() {
        self.mapView.centerCoordinate = self.currentLocation.coordinate
    }
    
    // Use the default marker
    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
        return nil
    }
    
    func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }

    // Set the alpha for all shape annotations to 1 (full opacity)
    func mapView(mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return 1
    }
    
    // Set the line width for polyline annotations
    func mapView(mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return 3.0
    }
    
    // Give our polyline a unique color by checking for its `title` property
    func mapView(mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return UIColor.blueColor()
    }
    
    // Dispose of any resources that can be recreated.
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension ViewController:GooglePlacesAutocompleteDelegate{
    func placeSelected(place: Place) {
        print(place.description)
//        let details = place.getDetails(result.latitude,resultlongitude:)
//        print details.latitude (lat: double, lng: double)
    }
    
    func placeViewClosed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
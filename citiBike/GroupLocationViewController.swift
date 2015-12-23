//
//  GroupLocationViewController.swift
//  citiBike
//
//  Created by 吴梦宇 on 12/17/15.
//  Copyright (c) 2015 ___mengyu wu___. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class GroupLocationViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate{
    
    var groupLocationInfo:DDBTableRow?
    
    var mapView: MGLMapView!
    
    var coordinates:[CLLocationCoordinate2D]=[]
    var currentLocation:CLLocationCoordinate2D?
    var point = MGLPointAnnotation()
    var timer = NSTimer()
    
    func updateLocation()
    {
        NSLog("hello World")
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
        //Query using GSI index table
        //What is the top score ever recorded for the game Meteor Blasters?
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.hashKeyValues = groupLocationInfo?.GroupTitle;
        queryExpression.hashKeyAttribute = "GroupTitle";
        queryExpression.indexName="Lat"
        
        dynamoDBObjectMapper .query(DDBTableRow.self, expression: queryExpression) .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                print("Error: \(task.error)", terminator: "")
                
                let alertController = UIAlertController(title: "Failed to query a test table.", message: task.error.description, preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel) { UIAlertAction -> Void in
                }
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                if (task.result != nil) {
                    let paginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                    for item in paginatedOutput.items as! [DDBTableRow] {
                        print("get: \(item.GroupTitle)")
                     
                            
                           let lat = Double(item.Lat!)
                           let log = Double(item.Log!)
                            
                           let coordinate=CLLocationCoordinate2D(latitude: lat,longitude: log)
                        
                            self.coordinates.append(coordinate)
                            self.currentLocation=coordinate
                        
                            self.mapView.removeAnnotation(self.point)
                            self.point.coordinate=coordinate
                            self.mapView.addAnnotation(self.point)
                      
                    }
                    
                    
                    
                    if (self.coordinates.count > 1){
                        let sourceIndex = self.coordinates.count - 1
                        let destinationIndex = self.coordinates.count - 2
                        
                        let c1 = self.coordinates[sourceIndex]
                        let c2 = self.coordinates[destinationIndex]
                        var a = [c1, c2]
                        let polyline = MGLPolyline(coordinates: &a, count: UInt(a.count))
                        self.mapView.addAnnotation(polyline)
                    }
                    
                     self.updateMapFrame()

                }
             
            }
            return nil
        })
        
       
        

    }
    
    func mapView(mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        // Set the alpha for all shape annotations to 1 (full opacity)
        return 1
    }
    
    func mapView(mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        // Set the line width for polyline annotations
        return 3.0
    }
    
    func mapView(mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        // Give our polyline a unique color by checking for its `title` property
        return UIColor.blueColor()
    }

    
    
    func isCoordEqual(p1:CLLocationCoordinate2D, p2:CLLocationCoordinate2D) -> Bool {
        return (p1.latitude==p2.latitude && p1.longitude==p2.latitude)
    }
    
    func updateMapFrame() {
        self.mapView.centerCoordinate = self.currentLocation!
    }
    
    override func viewWillAppear(animated: Bool) {
        self.coordinates.removeAll(keepCapacity: false)
        timer=NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "updateLocation", userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        timer.invalidate()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        var center=CLLocationCoordinate2D(latitude: 40.7326808,longitude: -73.9843407)
        var lat:Double = 40.7326808
        var log:Double = -73.9843407
        
        // Do any additional setup after loading the view.
        if let info=groupLocationInfo{
            print(self.groupLocationInfo?.GroupId, terminator: "")
            lat = Double(info.Lat!)
            log = Double(info.Log!)
            
            center=CLLocationCoordinate2D(latitude: lat,longitude: log)
            // Declare the annotation `point` and set its coordinates, title, and subtitle
        }
        
        
        
        // initialize the map view
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        // set the map's center coordinate
        
        mapView.setCenterCoordinate(center,
            zoomLevel: 12, animated: false)
        
        view.addSubview(mapView)
        
        mapView.delegate=self
        //mapView.showsUserLocation=true
        
        point.coordinate = center
        point.title = groupLocationInfo?.GroupTitle ?? ""
        let latLabel = round(lat*100)/100
        let logLabel = round(log*100)/100
        point.subtitle="\(latLabel) \(logLabel)"
        
        
        // Add annotation `point` to the map
        mapView.addAnnotation(point)
        coordinates.append(center)
        currentLocation=center
    }
    
    
    func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

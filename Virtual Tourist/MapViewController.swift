//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Nick on 6/23/16.
//  Copyright © 2016 Nick Adcock. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    // Get the stack
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let locationManager = CLLocationManager()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MKMapView.addAnnotation(_:)))
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
        
        let stack = delegate.stack
        mapView.addAnnotations(fetchAllPins(stack))
    
        let region = getRegionFromDefualts()
        if (region != nil) {
            self.mapView.setRegion(region!, animated: false)
        } else {
            // For use in foreground
            
            if (CLLocationManager.locationServicesEnabled())
            {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestWhenInUseAuthorization()
                locationManager.requestLocation()
            }
            
        }
        
    }
    
    func fetchAllPins(stack: CoreDataStack) -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            return try stack.context.executeFetchRequest(fetchRequest) as! [Pin]
        } catch {
            print("Error in fectchAllActors()")
        }
        
        return [Pin]()
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        setRegionInUserDefaults(mapView.region)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager has triggered")
        let location = locations.last
        
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        setRegionInUserDefaults(region)
        mapView.setRegion(region, animated: true)
        userDefaults.setBool(true, forKey: "initialRegionSet")
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
        manager.requestLocation()
    }
    
    func setRegionInUserDefaults(region: MKCoordinateRegion) {
        userDefaults.setDouble(region.center.latitude, forKey: "region.center.latitude")
        userDefaults.setDouble(region.center.longitude, forKey: "region.center.longitude")
        userDefaults.setDouble(region.span.longitudeDelta, forKey: "region.span.longitudeDelta")
        userDefaults.setDouble(region.span.latitudeDelta, forKey: "region.span.latitudeDelta")
    }
    
    func getRegionFromDefualts() -> MKCoordinateRegion? {
        let regionCenterLatitude, regionCenterLongitude, regionSpanLatDelta, regionSpanLongDelta: Double?
        
        if userDefaults.boolForKey("initialRegionSet"){
            regionCenterLatitude = userDefaults.doubleForKey("region.center.latitude")
            regionCenterLongitude = userDefaults.doubleForKey("region.center.longitude")
            regionSpanLatDelta = userDefaults.doubleForKey("region.span.latitudeDelta")
            regionSpanLongDelta = userDefaults.doubleForKey("region.span.longitudeDelta")
        } else {
            return nil
        }
        
        let regionCenter = CLLocationCoordinate2DMake(regionCenterLatitude!, regionCenterLongitude!)
        let regionSpan = MKCoordinateSpan(latitudeDelta: regionSpanLatDelta!, longitudeDelta: regionSpanLongDelta!)
        
        return MKCoordinateRegion(center: regionCenter, span: regionSpan)
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let pin = Pin(annotationLatitude: newCoordinates.latitude, annotationLongitude: newCoordinates.longitude, context: delegate.stack.context)
            //annotation.coordinate = newCoordinates
            self.addPinToMap(pin)
            
            
        }
    }
        
    func addPinToMap(pin: Pin) -> Void {
        
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude), completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                print(pm)
                
                if (pm.subLocality != nil) {
                    pin.title = pm.subLocality!
                    self.mapView.addAnnotation(pin)
                    return
                } else if (pm.locality != nil) {
                    pin.title = pm.locality!
                    self.mapView.addAnnotation(pin)
                    return
                } else if (pm.subAdministrativeArea != nil) {
                    pin.title = pm.subAdministrativeArea! + ", " + pm.administrativeArea!
                    self.mapView.addAnnotation(pin)
                    return
                } else if (pm.administrativeArea != nil) {
                    pin.title = pm.administrativeArea!
                    self.mapView.addAnnotation(pin)
                    return
                } else {
                    pin.title = "Unknown Location"
                    self.mapView.addAnnotation(pin)
                    return
                }
            }
            else {
                print("Problem with the data received from geocoder")
                return
            }
        })
    
        

    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.animatesDrop = true
//            let iconView = UIImageView(image: UIImage(named: "Image"))
//            iconView.frame = CGRectMake(0, 0, 30, 30)
//            pinView!.leftCalloutAccessoryView = iconView
            pinView!.pinTintColor = UIColor(colorLiteralRed: 145/255, green: 134/255, blue: 209/255, alpha: 1.0)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        performSegueWithIdentifier("toPhotoViewController", sender: nil)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


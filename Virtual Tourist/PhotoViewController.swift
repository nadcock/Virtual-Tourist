//
//  PhotoViewController.swift
//  Virtual Tourist
//
//  Created by Nick on 7/7/16.
//  Copyright © 2016 Nick Adcock. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var navBarTitle: UINavigationItem!
    @IBOutlet var map: MKMapView!
    @IBOutlet var photoCV: UICollectionView!
    
    var pin: Pin?
    
    override func viewDidLoad() {
        navBarTitle.title = pin!.title
        map.addAnnotation(pin!)
        self.map.showAnnotations(self.map.annotations, animated: false)
    }
    
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
}

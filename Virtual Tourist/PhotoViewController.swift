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
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var navBarTitle: UINavigationItem!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var newCollectionButton: UIBarButtonItem!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var bottomBar: UIToolbar!
    @IBOutlet var collectionViewConstraint: NSLayoutConstraint!
    
    var pin: Pin?
    var photoArray = [Photo]()
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).stack.context
    
    var selectedIndexes   = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    lazy var fetchedResultsController: NSFetchedResultsController =  {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.pin!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.context,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        mapView.delegate = self
        
        navBarTitle.title = pin!.title
        mapView.addAnnotation(pin!)
        mapView.scrollEnabled = false
        self.mapView.showAnnotations(self.mapView.annotations, animated: false)
        fetchedResultsController.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        if pin!.isDownloading == true {
            newCollectionButton.enabled = false
        }
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        if fetchedResultsController.fetchedObjects!.count < 1 {
            collectionView.hidden = true
            bottomBar.hidden = true
            errorLabel.hidden = false
            collectionViewConstraint.active = false
        } else {
            errorLabel.hidden = true
        }
    }
    
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func getNewCollection(sender: UIBarButtonItem) {
        newCollectionButton.enabled = false
        photoArray = fetchedResultsController.fetchedObjects as! [Photo]
        for photo in photoArray {
            let placeholder = UIImage(named: "Placeholder")!
            let placeholderData: NSData = UIImagePNGRepresentation(placeholder)!
            photo.photo = placeholderData
        }
        FlickrSearch.sharedInstance.getImageFromFlickrForPin(pin!, currentPhotos: photoArray, context: self.context)
    }
    
    
    //MARK: CollectionViewDataSource Required Methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections!.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let CellIdentifier = "PhotoCell"
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        if let backgroundImage = photo.photo {
            cell.image.image = UIImage(data: backgroundImage)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let alert = UIAlertController(title: "Delete Photo", message: "Do you want to remove this photo?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction) in
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction) in
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            self.context.deleteObject(photo)
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths  = [NSIndexPath]()
        updatedIndexPaths  = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            //context.deleteObject(photoArray[(newIndexPath!.item - (pin!.pagesOnFlickr!.integerValue))])
            insertedIndexPaths.append(newIndexPath!)
        case .Update:
            updatedIndexPaths.append(indexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion: { (sucess) -> Void in
                if self.pin!.isDownloading == false {
                    self.newCollectionButton.enabled = true
                }
        })
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let numberOfItemsPerRow = 3
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.minimumInteritemSpacing = 2
        flowLayout.minimumLineSpacing = 2
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfItemsPerRow - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfItemsPerRow))
        return CGSize(width: size, height: size)
    }
}

extension PhotoViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.animatesDrop = false
            pinView!.pinTintColor = UIColor(colorLiteralRed: 145/255, green: 134/255, blue: 209/255, alpha: 1.0)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

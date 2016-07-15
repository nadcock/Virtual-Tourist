//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Nick Adcock on 7/13/16.
//  Copyright © 2016 Nick Adcock. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var title: String?
    @NSManaged var pagesOnFlickr: NSNumber?
    @NSManaged var photo: NSSet?

}

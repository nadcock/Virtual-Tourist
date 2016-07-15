//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Nick on 7/7/16.
//  Copyright © 2016 Nick Adcock. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(photoPin: Pin, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        pin = photoPin
    }

}

//
//  PhotoViewController.swift
//  Virtual Tourist
//
//  Created by Nick on 7/7/16.
//  Copyright © 2016 Nick Adcock. All rights reserved.
//

import Foundation
import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var navBarTitle: UINavigationItem!
    
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    func test() {
        navBarTitle.title = "Blue"
    }
}

//
//  Flickr.swift
//  Virtual Tourist
//
//  Created by Nick Adcock on 7/11/16.
//  Copyright © 2016 Nick Adcock. All rights reserved.
//

import Foundation
import CoreData

class FlickrSearch {
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "0f9acffb32ae94a5ae5b80a7702b255d"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let PER_PAGE = "21"
    
    static let sharedInstance = FlickrSearch()
    
    func getMethodArguments(pin: Pin) -> [String : AnyObject] {
        var arguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "lat": pin.latitude!.stringValue,
            "lon": pin.longitude!.stringValue,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": PER_PAGE
        ]
        
        if let pages = pin.pagesOnFlickr {
            let page = Int((arc4random_uniform(UInt32(pages.integerValue)))) + 1
            arguments["page"] = String(page)
        }
        
        return arguments
    }
    
    func getImageFromFlickrForPin(pin: Pin, currentPhotos: [Photo], context: NSManagedObjectContext) {
        
        
        let methodArguments = getMethodArguments(pin)
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        pin.isDownloading = true
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            var pages = Int()
            
            for (key, value) in photosDictionary {
                if key as! String == "pages" {
                    pages = value.integerValue
                }
            }
            
            if pages > 40 {
                pin.pagesOnFlickr = 40
            } else {
                pin.pagesOnFlickr = pages
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotos = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotos > 0 {
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
                let numberOfPhotosToDownload = photosArray.count
                var photosDownloaded = 1
                
                if photosArray.count == currentPhotos.count {
                    for (index, photo) in photosArray.enumerate() {
                        let currentPhoto = currentPhotos[index]
                        let photoDictionary = photo as [String: AnyObject]
                        
                        /* GUARD: Does our photo have a key for 'url_m'? */
                        guard let imageUrlString = photoDictionary["url_m"] as? String else {
                            print("Cannot find key 'url_m' in \(photoDictionary)")
                            return
                        }
                        
                        self.downloadPhoto(imageUrlString, photo: currentPhoto) { (photo: Photo, downloadedImage: NSData?) -> Void in
                            if let downloadedImage = downloadedImage {
                                photo.photo = downloadedImage
                                
                                if photosDownloaded == numberOfPhotosToDownload {
                                    pin.isDownloading = false
                                } else {
                                    photosDownloaded += 1
                                }
                                
                            }
                        }
                    }
                } else if currentPhotos.count == 0 {
                    for (_, photo) in photosArray.enumerate() {
                        let photoDictionary = photo as [String: AnyObject]
                        
                        /* GUARD: Does our photo have a key for 'url_m'? */
                        guard let imageUrlString = photoDictionary["url_m"] as? String else {
                            print("Cannot find key 'url_m' in \(photoDictionary)")
                            return
                        }
                        
                        let newPhoto = Photo(photoPin: pin, context: context)
                        
                        self.downloadPhoto(imageUrlString, photo: newPhoto) { (photo: Photo, downloadedImage: NSData?) -> Void in
                            if let downloadedImage = downloadedImage {
                                photo.photo = downloadedImage
                                
                                if photosDownloaded == numberOfPhotosToDownload {
                                    pin.isDownloading = false
                                } else {
                                    photosDownloaded += 1
                                }
                            }
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
    
    
    
    func downloadPhoto(url: String, photo: Photo, handler: (Photo, NSData) -> Void) {
        let imageURL = NSURL(string: url)
        
        if let imageData = NSData(contentsOfURL: imageURL!) {
            handler(photo, imageData)
        } else {
            print("Image does not exist at \(imageURL)")
        }
        
    }
    
    // MARK: Escape HTML Parameters
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

}

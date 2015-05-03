//
//  ViewController.swift
//  Giphy
//
//  Created by Derrick  Ho on 5/1/15.
//  Copyright (c) 2015 Derrick  Ho. All rights reserved.
//

import UIKit

private let baseURL = "http://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC"
class ViewController: UIViewController, UISearchBarDelegate {
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var bigImageView: UIImageView!
    var smallImage: UIImage? {
        didSet {
            self.imageView.image = smallImage
            showReload()
        }
    }
    var bigImage: UIImage? {
        didSet {
            self.bigImageView.image = bigImage
            showReload()
        }
    }
    
    func showReload() {
        var b = smallImage != nil && bigImage != nil
        self.navigationItem.rightBarButtonItem?.enabled = b
        
        self.searchBar.hidden = !b
        //self.searchBar.userInteractionEnabled = b
        UIView.animateWithDuration(0.5 as NSTimeInterval, animations: { () -> Void in
            self.searchBar.alpha =  b ? CGFloat(1.0) : CGFloat(0.2)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.imageView.layer.borderColor = UIColor.blackColor().CGColor
        self.imageView.layer.borderWidth = 1
        self.bigImageView.layer.borderColor = UIColor.redColor().CGColor
        self.bigImageView.layer.borderWidth = 1
        
        self.searchBar.delegate = self
        self.searchBar.text = "cats"
        self.getImage()
        
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.getImage()
        UIApplication.sharedApplication().sendAction("resignFirstResponder", to: nil, from: nil, forEvent: nil)
    }
    
    @IBAction func getImage() {
        var query = self.searchBar.text
        query = query.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        query = query.stringByReplacingOccurrencesOfString(" ", withString: "%20")
        if query != "" {
            query = "&tag=\(query)"
        }
        let combinedUrl = NSURL(string: baseURL + query + "&rating=pg-13")!
        bigImage = nil
        smallImage = nil
        showReload()
        var loaderSmall = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        imageView.addSubview(loaderSmall)
        loaderSmall.startAnimating()
        var loaderBig = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        bigImageView.addSubview(loaderBig)
        loaderBig.startAnimating()
        NSURLSession.sharedSession().dataTaskWithURL(combinedUrl, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            if let d =  NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? [String : AnyObject] {
                if let data = d["data"] as? [String : AnyObject] {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                        let prefixSmall = "fixed_height_small_"
                        if let stillURLPath = data[prefixSmall + "still_url"] as? String,
                            stillURL = NSURL(string: stillURLPath),
                            stillData = NSData(contentsOfURL: stillURL),
                            stillImage = UIImage(data: stillData) {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.smallImage = stillImage
                                    loaderSmall.stopAnimating()
                                    loaderSmall.removeFromSuperview()
                                })
                        }
                        
                    })
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), { () -> Void in
                        let prefixSmall = "image_original_"//"fixed_height_downsampled_"
                        if let downURLPath = data[prefixSmall + "url"] as? String,
                            downURL = NSURL(string: downURLPath),
                            downData = NSData(contentsOfURL: downURL),
                            downImage = UIImage(data: downData) {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.bigImage = downImage
                                    loaderBig.stopAnimating()
                                    loaderBig.removeFromSuperview()
                                })
                        }
                        
                    })

                }
            }
        }).resume()
    }

}


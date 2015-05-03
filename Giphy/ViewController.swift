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
    @IBOutlet weak var bigImageView: UIImageView!
    var smallGifData: NSData? {
        didSet {
            (self.bigImageView as! FLAnimatedImageView).animatedImage = FLAnimatedImage(animatedGIFData: smallGifData)
            showReload()
        }
    }
    var bigGifData: NSData? {
        didSet {
            (self.bigImageView as! FLAnimatedImageView).animatedImage = FLAnimatedImage(animatedGIFData: bigGifData)
            showReload()
        }
    }
    
    func showReload() {
        var b = smallGifData != nil && bigGifData != nil
        self.navigationItem.rightBarButtonItem?.enabled = b
        
        self.searchBar.hidden = !b
        UIView.animateWithDuration(0.5 as NSTimeInterval, animations: { () -> Void in
            self.searchBar.alpha =  b ? CGFloat(1.0) : CGFloat(0.2)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.bigImageView.layer.borderColor = UIColor.redColor().CGColor
        self.bigImageView.layer.borderWidth = 1
        
        self.searchBar.delegate = self
        self.searchBar.text = "cats"
        self.getImage()
        
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.getImage()
       
    }
    
    @IBAction func getImage() {
        UIApplication.sharedApplication().sendAction("resignFirstResponder", to: nil, from: nil, forEvent: nil)
        var query = self.searchBar.text
        query = query.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        query = query.stringByReplacingOccurrencesOfString(" ", withString: "%20")
        if query != "" {
            query = "&tag=\(query)"
        }
        let combinedUrl = NSURL(string: baseURL + query + "&rating=pg-13")!
        bigGifData = nil
        smallGifData = nil
        showReload()
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
                            stillData = NSData(contentsOfURL: stillURL) {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.smallGifData = stillData
                                })
                        }
                        let prefixBig = "image_original_"
                        if let downURLPath = data[prefixBig + "url"] as? String,
                            downURL = NSURL(string: downURLPath),
                            downData = NSData(contentsOfURL: downURL) {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.bigGifData = downData
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


//
//  MovieDetailViewController.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - MovieDetailViewController: UIViewController

class MovieDetailViewController: UIViewController {
    
    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var isFavorite = false
    var movie: Movie?
    
    // MARK: Outlets
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let movie = movie {
            
            // setting some defaults...
            posterImageView.image = UIImage(named: "film342.png")
            titleLabel.text = movie.title
            
            /* TASK A: Get favorite movies, then update the favorite buttons */
            /* 1A. Set the parameters */
            let methodParameters = [
                Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
                Constants.TMDBParameterKeys.SessionID: appDelegate.sessionID!
            ]
            
            /* 2/3. Build the URL, Configure the request */
            let request = NSMutableURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/account/\(appDelegate.userID!)/favorite/movies"))
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            /* 4A. Make the request */
            let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    print("There was an error with your request: \(error)")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                    print("Your request returned a status code other than 2xx!")
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    print("No data was returned by the request!")
                    return
                }
                
                /* 5A. Parse the data */
                let parsedResult: AnyObject!
                do {
                    parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                } catch {
                    print("Could not parse the data as JSON: '\(data)'")
                    return
                }
                
                /* GUARD: Did TheMovieDB return an error? */
                if let _ = parsedResult[Constants.TMDBResponseKeys.StatusCode] as? Int {
                    print("TheMovieDB returned an error. See the '\(Constants.TMDBResponseKeys.StatusCode)' and '\(Constants.TMDBResponseKeys.StatusMessage)' in \(parsedResult)")
                    return
                }
                
                /* GUARD: Is the "results" key in parsedResult? */
                guard let results = parsedResult[Constants.TMDBResponseKeys.Results] as? [[String:AnyObject]] else {
                    print("Cannot find key '\(Constants.TMDBResponseKeys.Results)' in \(parsedResult)")
                    return
                }
                
                /* 6A. Use the data! */
                let movies = Movie.moviesFromResults(results)
                self.isFavorite = false
                
                for movie in movies {
                    if movie.id == self.movie!.id {
                        self.isFavorite = true
                    }
                }
                
                performUIUpdatesOnMain {
                    self.favoriteButton.tintColor = (self.isFavorite) ? nil : UIColor.blackColor()
                }
            }
            
            /* 7A. Start the request */
            task.resume()
            
            /* TASK B: Get the poster image, then populate the image view */
            if let posterPath = movie.posterPath {
                
                /* 1B. Set the parameters */
                // There are none...
                
                /* 2B. Build the URL */
                let baseURL = NSURL(string: appDelegate.config.baseImageURLString)!
                let url = baseURL.URLByAppendingPathComponent("w342").URLByAppendingPathComponent(posterPath)
                
                /* 3B. Configure the request */
                let request = NSURLRequest(URL: url)
                
                /* 4B. Make the request */
                let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
                    
                    /* GUARD: Was there an error? */
                    guard (error == nil) else {
                        print("There was an error with your request: \(error)")
                        return
                    }
                    
                    /* GUARD: Did we get a successful 2XX response? */
                    guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                        print("Your request returned a status code other than 2xx!")
                        return
                    }
                    
                    /* GUARD: Was there any data returned? */
                    guard let data = data else {
                        print("No data was returned by the request!")
                        return
                    }
                    
                    /* 5B. Parse the data */
                    // No need, the data is already raw image data.
                    
                    /* 6B. Use the data! */
                    if let image = UIImage(data: data) {
                        performUIUpdatesOnMain {
                            self.posterImageView!.image = image
                        }
                    } else {
                        print("Could not create image from \(data)")
                    }
                }
                
                /* 7B. Start the request */
                task.resume()
            }
        }
    }
    
    // MARK: Favorite Actions
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        
        let shouldFavorite = !isFavorite
        let sessionID = appDelegate.sessionID
        
        let parameters : [String: String!] = [Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey, Constants.TMDBParameterKeys.SessionID: sessionID!]
        let request = NSMutableURLRequest(URL: appDelegate.tmdbURLFromParameters(parameters, withPathExtension: "/account/\(appDelegate.userID!)/favorite/movies"))
        
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "{\"media_type\":\"movie\", \"media_id\": \(movie!.id),\"favorite\": \(shouldFavorite)}".dataUsingEncoding(NSUTF8StringEncoding)

        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            func displayError(error: String){
                print(error)
                
            }
            guard (error == nil) else{
                displayError("\(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else{
                displayError("Something goes wrong here with errro: \(error)")
                return
            }
            
            /* 5. Parse the data */
            guard let data = data else {
                print("No data response")
                return
            }
            
            var parseData: AnyObject!
            do{
                parseData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            }catch{
                print("Error in parsing data")
                return
            }
            
            /* 6. Use the data! */
            
            guard let status = parseData[Constants.TMDBResponseKeys.StatusCode] as? Int else {
                displayError("Error in posting favourite")
                return
            }
            
            guard let statusMessage = parseData["status_message"] as? String else{
                displayError("Unable to receive message")
                return
            }
            
            print("\(status) \(statusMessage)")
            
            if shouldFavorite && !(status == 12 || status == 1) {
                print("Error code \(status)")
                return
            }else if (!shouldFavorite && status != 13){
                print("Error code \(status)")
                return
            }
            
            self.isFavorite = shouldFavorite
            
            performUIUpdatesOnMain({ () -> Void in
                self.favoriteButton.tintColor = (shouldFavorite) ? nil : UIColor.blackColor()
            })
            
            
        }
        task.resume()
        performUIUpdatesOnMain {
            self.favoriteButton.tintColor = (shouldFavorite) ? nil : UIColor.blackColor()
        }
        
    }
}
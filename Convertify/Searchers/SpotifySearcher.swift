//
//  SpotifySearcher.swift
//  Spotify to Apple Music
//
//  Handles Spotify querying and maintains information about Spotify
//
//  Created by Hayden Hong on 8/6/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation

public class spotifySearcher: MusicSearcher {
    let serviceName: String = "Spotify"
    let serviceColor: UIColor = UIColor(red: 0.52, green: 0.74, blue: 0.00, alpha: 1.0)

    var id: String?
    var name: String?
    var artist: String?
    var type: String?
    var url: String?
    var token: String?

    init(completion: @escaping (Error?) -> Void) {
        let parameters = ["client_id": Auth.spotifyClientID,
                          "client_secret": Auth.spotifyClientSecret,
                          "grant_type": "client_credentials"]

        Alamofire.request("https://accounts.spotify.com/api/token", method: .post, parameters: parameters, headers: nil)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let result = response.result.value as! NSDictionary
                    self.token = result.value(forKey: "access_token") as? String
                    completion(nil)
                }

                case .failure: do {
                    // FIXME: Add a real error here
                    completion(MusicSearcherErrors.noSearchResultsError)
                }
                }
            }
    }

    /// Searches the Spotify API from a link and extracs the information from it
    ///
    /// - Parameter link: Link to search for within the Spotify API
    /// - Parameter completion: What to run after searching is complete
    /// - Returns: DataRequest from querying the Spotify API
    func search(link: String, completion: @escaping (Error?) -> Void) {
        // Reset the variables
        id = nil
        name = nil
        artist = nil
        type = nil

        let linkData = link.replacingOccurrences(of: SearcherURL.spotify, with: "").split(separator: "/")
        if linkData.count != 2 {
            print("It looks like the link was formatted incorrectly (link = \(link)")
            completion(MusicSearcherErrors.noSearchResultsError)
        } else {
            type = String(linkData[0])
            id = String(String(linkData[1]).split(separator: "?")[0])
            let headers: HTTPHeaders = ["Authorization": "Bearer \(token!)"]

            // Creates the request
            Alamofire.request("https://api.spotify.com/v1/\(type!)s/\(id!)", headers: headers)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success: do {
                        let json = response.result.value as! NSDictionary
                        // Gets the name of the content
                        self.name = json.object(forKey: "name") as? String

                        // Skips finding artist when matching artist links
                        if self.type != "artist" {
                            self.artist = ((json.object(forKey: "artists") as! NSArray)[0] as AnyObject).object(forKey: "name") as? String
                        }

                        // Run completion with no errors
                        completion(nil)
                    }

                    case let .failure(error): do { completion(error) }
                    }
                }
        }
    }

    /// Searches Spotify for the name and type
    ///
    /// - Parameters:
    ///   - name: Name of resource to search for
    ///   - type: Type of resource to search for
    ///   - completion: What to run after searching is complete
    /// - Returns: DataRequest from the Spotify API
    func search(name: String, type: String, completion: @escaping (Error?) -> Void) {
        self.type = type == "song" ? "track" : type

        let headers: HTTPHeaders = ["Authorization": "Bearer \(self.token ?? "")"]
        let parameters: Parameters = ["q": name, "type": self.type!]

        Alamofire.request("https://api.spotify.com/v1/search/", parameters: parameters, headers: headers).responseJSON { response in
            if let result = response.result.value {
                // Gets the JSON value
                let JSON = result as! NSDictionary

                // Gets the data of the type from the JSON
                let data = JSON.object(forKey: (self.type ?? "") + "s") as AnyObject

                // Ensures there actually are search results
                if (data.object(forKey: "total") as! Int) > 0 {
                    // Gets the first search result
                    let items = (data.object(forKey: "items") as! NSArray)[0] as AnyObject
                    // Gets and sets the URL of the first search result
                    self.url = (items.object(forKey: "external_urls") as AnyObject).object(forKey: "spotify") as? String
                    completion(nil)
                } else {
                    completion(MusicSearcherErrors.noSearchResultsError)
                }
            }
        }
    }

    /// Opens the URL
    func open() {
        if url != nil {
            UIApplication.shared.open(URL(string: url!)!, options: [:])
        }
    }

    /// Handles the "dirty work" setting the name, type, and artist
    ///
    /// - Parameters:
    ///   - id: identifierof the Spotify resource
    ///   - type: Type of the Spotify resource (Example: "artist")
    /// - Returns: The DataRequest made using the Spotify API
    private func handleSpotifyID(id: String, type: String) -> DataRequest {
        let headers = ["Authorization": "Bearer \(token ?? "")"]
        // Creates the request
        return Alamofire.request("https://api.spotify.com/v1/\(type)s/\(id)", headers: headers).responseJSON { response in
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                // Gets the name of the content
                self.name = JSON.object(forKey: "name") as? String

                // Skips finding artist when matching artist links
                if type != "artist" {
                    self.artist = ((JSON.object(forKey: "artists") as! NSArray)[0] as AnyObject).object(forKey: "name") as? String
                }

                // Sets the type
                self.type = type
            }
        }
    }
}

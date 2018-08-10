//
//  SpotifySearcher.swift
//  Spotify to Apple Music
//
//  Created by Hayden Hong on 8/6/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation
import SpotifyLogin

/// Handles Spotify querying and maintains information about Spo
public class spotifySearcher {
    var id: String?
    var name: String?
    var artist: String?
    var type: String?
    var url: String?
    var token: String?
    
    /// Searches the Spotify API from a link and extracs the information from it
    ///
    /// - Parameter link: Link to search for within the Spotify API
    /// - Returns: DataRequest from querying the Spotify API
    func search(link: String) -> DataRequest? {
        // Reset the variables
        id = nil
        name = nil
        artist = nil
        type = nil

        let linkData = link.replacingOccurrences(of: "https://open.spotify.com/", with: "").split(separator: "/")
        if linkData.count != 2 {
            print("It looks like the link was formatted incorrectly (link = \(link)")
        } else {
            let type = String(linkData[0])
            let id = String(String(linkData[1]).split(separator: "?")[0])
            print("Getting \(type)")

            // Get a lot of the data from it
            return handleSpotifyID(id: id, type: type)
        }
        return nil
    }
    
    /// Searches Spotify for the name and type
    ///
    /// - Parameters:
    ///   - name: Name of resource to search for
    ///   - type: Type of resource to search for
    /// - Returns: DataRequest from the Spotify API
    func search(name: String, type: String) -> DataRequest {
        let safeName = name.replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: " ", with: "%20")
        self.type = convertTypeToSpotify(type: type)
        let headers = ["Authorization": "Bearer \(self.token ?? "")"]
        return Alamofire.request("https://api.spotify.com/v1/search?q=\(safeName)&type=\(self.type ?? "")", headers: headers).responseJSON { response in
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                let data = JSON.object(forKey: (self.type ?? "") + "s") as AnyObject
                let items = (data.object(forKey: "items") as! NSArray)[0] as AnyObject
                self.url = (items.object(forKey: "external_urls") as AnyObject).object(forKey: "spotify") as? String
                // self.name = items.object(forKey: "name") as? String
                // self.artist = ((items.object(forKey: "artists") as! NSArray)[0] as AnyObject).object(forKey:"name") as? String
            }
        }
    }

    
    /// Converts the type from Apple Music to Spotify
    ///
    /// - Parameter type: the type from Apple Music (example: song vs. track)
    /// - Returns: the type for Spotify
    private func convertTypeToSpotify(type: String) -> String {
        switch type {
        case "song":
            return "track"
        case "album":
            return "album"
        case "artist":
            return "artist"
        default:
            return type
        }
    }
    
    
    /// Opens the URL
    func open() {
        if url != nil {
            UIApplication.shared.openURL(URL(string: url!)!)
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

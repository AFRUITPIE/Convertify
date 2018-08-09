//
//  SpotifySearcher.swift
//  Spotify to Apple Music
//
//  Created by Hayden Hong on 8/6/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Foundation
import Alamofire
import SpotifyLogin

public class spotifySearcher {
    var id: String?
    var name: String?
    var artist: String?
    var type: String?
    var url: String?
    var token: String?
    
    func search(link: String) -> DataRequest? {
        let linkData = link.replacingOccurrences(of: "https://open.spotify.com/", with: "").split(separator: "/")
        if linkData.count != 2 {
            print("It looks like the link was formatted incorrectly (link = \(link)")
        } else {
            let type = String(linkData[0])
            let id = String(String(linkData[1]).split(separator: "?")[0])
            print("Getting \(type)")
            
            // Get a lot of the data from it
            return self.handleSpotifyID(id: id, type: type)
        }
        return nil;
    }
    
    // TODO
    func search(name: String, type: String) -> DataRequest {
        self.type = convertTypeToSpotify(type: type)
        let headers = ["Authorization": "Bearer \(self.token ?? "")"]
        return Alamofire.request("https://api.spotify.com/v1/search?q=\(name.replacingOccurrences(of:" ", with: "+"))&type=\(type)", headers: headers).responseJSON { response in
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                let data = ((JSON.object(forKey: (self.type! + "s")) as AnyObject).object(forKey: "items") as! NSArray)[0] as AnyObject
                self.url = (data.object(forKey: "external_urls") as AnyObject).object(forKey: "spotify") as? String
                self.name = data.object(forKey: "name") as? String
                self.artist = (data.object(forKey: "artists") as AnyObject).object(forKey:"name") as? String
            }
        }
    }
    
    func convertTypeToSpotify(type: String) -> String {
        switch type {
        case "song":
            return "track"
        case "album":
            return "albums"
        case "artist":
            return "artists"
        default:
            return type
        }
    }
    
    func open() {
        if (url != nil) {
            UIApplication.shared.openURL(URL(string: url!)!)
        }
    }
    
    private func handleSpotifyID(id: String, type: String) -> DataRequest {
        let headers = ["Authorization": "Bearer \(token ?? "")"]
        // Creates the request
        return Alamofire.request("https://api.spotify.com/v1/\(type)s/\(id)", headers: headers).responseJSON { response in
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                // Gets the name of the content
                self.name = JSON.object(forKey: "name") as? String
                
                // Skips finding artist when matching artist links
                if (type != "artist") {
                    self.artist = ((JSON.object(forKey: "artists") as! NSArray)[0] as AnyObject).object(forKey: "name") as? String
                }
                self.type = type
            }
        }
    }
}

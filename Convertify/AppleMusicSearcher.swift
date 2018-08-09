//
//  AppleMusicSearcher.swift
//  Spotify to Apple Music
//
//  Created by Hayden Hong on 8/6/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Foundation
import Alamofire

public class appleMusicSearcher {
    var id: String?
    var name: String?
    var artist: String?
    var type: String?
    var url: String?
    
    func search(link: String) -> DataRequest? {
        parseLinkData(link: link)
        
        let headers = ["Authorization": "Bearer \(Authentication.appleMusicKey)"]
        return Alamofire.request("https://api.music.apple.com/v1/catalog/us/\(self.type!)s/\(self.id ?? "")", headers: headers).responseJSON { response in
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                let data: AnyObject = ((((result as! NSDictionary)
                    .object(forKey: "data") as! NSArray)[0]) as AnyObject)
                    .object(forKey: "attributes") as AnyObject
                self.name = data.object(forKey: "name") as? String
                
                if (self.type != "artist") {
                    self.artist = data.object(forKey: "artistName") as? String
                }
            }
        }
    }
    
    // Parses the data from the link and sets class variables accordingly
    private func parseLinkData(link: String) {
        url = link
        let linkData = link.replacingOccurrences(of: "https://itunes.apple.com/us/", with: "").split(separator: "/")
        type = String(linkData[0])
        // Handles "album" and "album -> song" issue
        if (type == "artist") {
            id = String(linkData[2])
        } else if (type == "album") {
            // If there's an equal sign in the link, it's a SONG within an album
            if (link.split(separator: "=").count == 2) {
                id = String(link.split(separator: "=")[1])
                type = "song"
            } else {
                id = String(linkData[2]) // FIXME: Horrific style you asshole
            }
        }
    }
    
    func search(name: String, type: String) -> DataRequest? {
        let term = name.replacingOccurrences(of: " ", with: "+")
        let headers = ["Authorization": "Bearer \(Authentication.appleMusicKey)"]
        let appleMusicType = convertSpotifyTypeToAppleMusicType(type: type)
        return Alamofire.request("https://api.music.apple.com/v1/catalog/us/search?term=\(term)&types=\(appleMusicType)", headers: headers).responseJSON { response in
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                // Get the URL from the returned data
                self.url = (((((JSON.object(forKey: "results") as AnyObject)
                    .object(forKey: appleMusicType) as AnyObject)
                    .object(forKey: "data") as! NSArray)[0] as AnyObject)
                    .object(forKey: "attributes") as AnyObject)
                    .object(forKey: "url") as? String
            }
        }
    }
    
    func open() {
        if (url != nil) {
            UIApplication.shared.openURL(URL(string: url!)!)
        }
    }
    
    private func convertSpotifyTypeToAppleMusicType(type: String) -> String {
        switch type {
        case "track":
            return "songs"
        default:
            return "\(type)s"
        }
    }
}


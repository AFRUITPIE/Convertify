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

func openInAppleMusic(link: String, token: String) {
    let linkData = link.replacingOccurrences(of: "https://open.spotify.com/", with: "").split(separator: "/")
    if linkData.count != 2 {
        print("It looks like the link was formatted incorrectly (link = \(link)")
    } else {
        let type = String(linkData[0])
        let id = String(String(linkData[1]).split(separator: "?")[0])
        print("Getting \(type)")
        
        // Open it in Apple Music
        handleSpotifyID(id: id, type: type, token: token)
    }
}

func handleSpotifyID(id: String, type: String, token: String) {
    var name: String?;
    var artist: String?;
    let headers = ["Authorization": "Bearer \(token)"]
    
    // Creates the request
    Alamofire.request("https://api.spotify.com/v1/\(type)s/\(id)", headers: headers).responseJSON { response in
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            
            // Gets the name of the content
            name = JSON.object(forKey: "name") as? String
            
            // Skips finding artist when matching artist links
            if (type != "artist") {
                artist = ((JSON.object(forKey: "artists") as! NSArray)[0] as AnyObject).object(forKey: "name") as? String
            }
            
            // Finally, open this in Apple Music
            openInAppleMusic(name: "\(name ?? "") \(artist ?? "")", type: type)
        }
    }
}

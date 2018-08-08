//
//  AppleMusicSearcher.swift
//  Spotify to Apple Music
//
//  Created by Hayden Hong on 8/6/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Foundation
import Alamofire

func openInAppleMusic(name: String, type: String) {
    let term = name.replacingOccurrences(of: " ", with: "+")
    print(term)
    let headers = ["Authorization": "Bearer \(Authentication.musicKey)"]
    let appleMusicType = convertSpotifyTypeToAppleMusicType(type: type)
    Alamofire.request("https://api.music.apple.com/v1/catalog/us/search?term=\(term)&types=\(appleMusicType)", headers: headers).responseJSON { response in
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            print(JSON)
            // Get the URL from the returned data
            let url = (((((JSON.object(forKey: "results") as AnyObject)
                .object(forKey: appleMusicType) as AnyObject)
                .object(forKey: "data") as! NSArray)[0] as AnyObject)
                .object(forKey: "attributes") as AnyObject)
                .object(forKey: "url") as! String
            UIApplication.shared.openURL(URL(string: url)!)
        }
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

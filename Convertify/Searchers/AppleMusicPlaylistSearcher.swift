//
//  AppleMusicPlaylistSearcher.swift
//  Convertify
//
//  Created by Hayden Hong on 1/24/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation

class AppleMusicPlaylistSearcher: PlaylistSearcher {
    private let token: String = Auth.appleMusicKey
    private var storefront: String = "us"
    private var playlistID: String?

    func getTrackList(link: String, completion: @escaping (Array<String>?, Error?) -> Void) {
        parseLinkData(link: link)

        let headers = ["Authorization": "Bearer \(self.token)"]
        Alamofire.request("https://api.music.apple.com/v1/catalog/us/playlists/\(playlistID ?? "")", headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let json = response.result.value as! NSDictionary

                    var trackList: Array<String> = []

                    // Gets array of track objects from the JSON
                    let trackObjects: NSArray = (((((json
                            .object(forKey: "data") as! NSArray)[0]) as AnyObject)
                            .object(forKey: "relationships") as AnyObject)
                        .object(forKey: "tracks") as AnyObject)
                        .object(forKey: "data") as! NSArray

                    // Adds the tracks to the tracklist
                    for track in trackObjects {
                        let trackName: String = ((track as AnyObject)
                            .object(forKey: "attributes") as AnyObject)
                            .object(forKey: "name") as! String
                        trackList.append(trackName)
                    }

                    completion(trackList, nil)
                }

                case let .failure(error): do {
                    completion(nil, error)
                }
                }
            }
    }

    private func parseLinkData(link: String) {
        playlistID = String(link.components(separatedBy: "/playlist/")[1].split(separator: "/")[1])
        storefront = String(link.components(separatedBy: "https://itunes.apple.com/")[1].split(separator: "/")[0])
    }
}

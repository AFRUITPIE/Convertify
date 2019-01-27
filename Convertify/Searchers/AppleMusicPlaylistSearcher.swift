//
//  AppleMusicPlaylistSearcher.swift
//  Convertify
//
//  Created by Hayden Hong on 1/24/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

class AppleMusicPlaylistSearcher: PlaylistSearcher {
    private let token: String = Auth.appleMusicKey
    private var storefront: String = "us"
    private var playlistID: String?

    func getTrackList(link: String, completion: @escaping ([String: String]?, Error?) -> Void) {
        parseLinkData(link: link)

        let headers = ["Authorization": "Bearer \(self.token)"]
        Alamofire.request("https://api.music.apple.com/v1/catalog/us/playlists/\(playlistID ?? "")", headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)

                    // Gets array of track objects
                    let trackObjects = data["data"][0]["relationships"]["tracks"]["data"].array

                    var trackList: [String: String] = [:]

                    // Adds the tracks to the tracklist
                    for track in trackObjects! {
                        let trackName: String = track["attributes"]["name"].stringValue
                        let artistName: String = track["attributes"]["artistName"].stringValue

                        if trackList[trackName] == nil {
                            trackList[trackName] = artistName
                        } else {
                            print("Duplicate track found: \(trackName)")
                        }
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

//
//  SpotifyPlaylistSearcher.swift
//  Convertify
//
//  Created by Hayden Hong on 1/26/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

class SpotifyPlaylistSearcher: PlaylistSearcher {
    func addPlaylist(trackList _: [String: String], playlistName _: String, completion _: @escaping (String?, Error?) -> Void) {}

    private var playlistID: String?

    /// Gets the track list for the shared playlist
    ///
    /// - Parameters:
    ///   - link: link to the playlist
    ///   - completion: function to handle the playlist
    func getTrackList(link: String, completion: @escaping ([String: String]?, String?, Error?) -> Void) {
        parseLinkData(link: link)

        login { token, error in
            if error != nil {
                completion(nil, nil, error)
            } else {
                let headers: HTTPHeaders = ["Authorization": "Bearer \(token!)"]

                // Request the playlist data
                Alamofire.request("https://api.spotify.com/v1/playlists/\(self.playlistID!)", headers: headers)
                    .validate()
                    .responseJSON { response in

                        switch response.result {
                        case .success: do {
                            let playlistData = JSON(response.result.value!)
                            let playlistName = playlistData["name"].stringValue

                            // Request the playlist's tracks
                            Alamofire.request("https://api.spotify.com/v1/playlists/\(self.playlistID!)/tracks", headers: headers)
                                .validate()
                                .responseJSON { response in
                                    switch response.result {
                                    case .success: do {
                                        let trackListData = JSON(response.result.value!)
                                        completion(self.getTrackListFromJSON(data: trackListData), playlistName, nil)
                                    }
                                    case let .failure(error): do {
                                        completion(nil, nil, error)
                                    }
                                    }
                                }
                        }
                        case let .failure(error): do {
                            // Something must have gone wrong with authentication :(
                            completion(nil, nil, error)
                        }
                        }
                    }
            }
        }
    }

    /// Completes the login for Spotify to get credentials
    ///
    /// - Parameter completion: the function to be run after login is complete
    private func login(completion: @escaping (String?, Error?) -> Void) {
        /**
         *
         *
         * FIXME: This is just straight up copied code from SpotifySearcher lol
         *
         *
         */

        let parameters = ["client_id": Auth.spotifyClientID,
                          "client_secret": Auth.spotifyClientSecret,
                          "grant_type": "client_credentials"]
        Alamofire.request("https://accounts.spotify.com/api/token", method: .post, parameters: parameters, headers: nil)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)
                    let token = data["access_token"].stringValue
                    completion(token, nil)
                }

                case let .failure(error): do {
                    // Something must have gone wrong with authentication :(
                    completion(nil, error)
                }
                }
            }
    }

    /// Parses the tracklist from the JSON file
    ///
    /// - Parameter data: json file
    /// - Returns: a dictionary of [String: String] that is [Song title: Main artist]
    private func getTrackListFromJSON(data: JSON) -> [String: String]? {
        var trackList: [String: String] = [:]

        let trackObjects = data["items"].array
        for track in trackObjects! {
            let trackName: String = track["track"]["name"].stringValue
            let artistName: String = track["track"]["artists"][0]["name"].stringValue

            if trackList[trackName] == nil {
                trackList[trackName] = artistName
            } else {
                print("Duplicate track found: \(trackName)")
            }
        }

        return trackList
    }

    /// Parses the playlist ID from the link
    ///
    /// - Parameter link: URL for Spotify playlist
    private func parseLinkData(link: String) {
        playlistID = String(link.components(separatedBy: "/playlist/")[1].split(separator: "?")[0])
    }
}

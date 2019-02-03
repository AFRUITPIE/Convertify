//
//  SpotifyPlaylistSearcher.swift
//  Convertify
//
//  Created by Hayden Hong on 1/26/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation
import SpotifyLogin
import SwiftyJSON

class SpotifyPlaylistSearcher: PlaylistSearcher {
    private let token: String?

    init(token: String?) {
        self.token = token
    }

    func addPlaylist(trackList: [String: String], playlistName: String, completion: @escaping (String?, Error?) -> Void) {
        // Get user ID
        getID(userToken: token ?? "") { id, error in
            if error == nil {
                // Create the playlist
                self.createSpotifyPlaylist(name: playlistName,
                                           userID: id ?? "",
                                           token: self.token ?? "") { playlistID, error in
                    if error == nil {
                        // Add tracks to that playlist
                        self.addTracksToPlaylist(trackList: trackList,
                                                 playlistID: playlistID ?? "",
                                                 userID: id ?? "") { link, error in
                            if error == nil {
                                completion(link ?? "", error)
                            } else {
                                completion(nil, error)
                            }
                        }
                    } else {
                        completion(nil, error)
                    }
                }
            } else {
                completion(nil, error)
            }
        }
    }

    private func getID(userToken: String, completion: @escaping (String?, Error?) -> Void) {
        let headers: HTTPHeaders = ["Authorization": "Bearer \(userToken)"]
        Alamofire.request("https://api.spotify.com/v1/me", headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success: do {
                // Success in getting user ID
                let data = JSON(response.result.value!)
                let userID = data["id"].stringValue
                completion(userID, nil)
            }
            case let .failure(error): completion(nil, error)
            }
        }
    }

    /// Creates and adds an empty Spotify playlist in the user's account
    ///
    /// - Parameters:
    ///   - name: name of the playlist
    ///   - token: user's access token for the playlist
    ///   - username: user's username
    ///   - completion: what to do with the playlist's link once it is created
    private func createSpotifyPlaylist(name: String, userID: String, token: String, completion: @escaping (String?, Error?) -> Void) {
        let parameters: Parameters = ["name": name,
                                      "description": "Created with Convertify for iOS",
                                      "public": false]

        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        Alamofire.request("https://api.spotify.com/v1/users/\(userID)/playlists/", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    // Successfully added playlist, use ID
                    let data = JSON(response.result.value!)
                    completion(data["id"].stringValue, nil)
                }
                case let .failure(error): completion(nil, error)
                }
            }
    }

    /// Adds tracks to a Spotify user's playlist
    ///
    /// - Parameters:
    ///   - trackList: list of tracks to add [Name: Artist]
    ///   - playlist: playlist's url
    ///   - completion: what to do with the playlist once adding tracks is done
    private func addTracksToPlaylist(trackList: [String: String], playlistID: String, userID: String, completion: @escaping (String?, Error?) -> Void) {
        var tempTrackList = trackList

        if trackList.count == 0 {
            completion(playlistID, nil)
        } else {
            let track = tempTrackList.popFirst()

            // Get the Spotify's track ID
            spotifySearcher(token: token ?? "")
                .search(name: "\(track?.key ?? "") \(track?.value ?? "")", type: "track") { trackLink, error in
                    if error == nil {
                        // Create a request for adding the track ID to the playlist
                        let trackID = String(trackLink!.split(separator: "/").last!)

                        let headers: HTTPHeaders = ["Authorization": "Bearer \(self.token ?? "")"]
                        let parameters: Parameters = ["uris": ["spotify:track:\(trackID)"]]
                        Alamofire.request("https://api.spotify.com/v1/playlists/\(playlistID)/tracks", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
                            switch response.result {
                            case .success: do {
                                // Recursively add the rest of the tracks to the playlist
                                self.addTracksToPlaylist(trackList: tempTrackList, playlistID: playlistID, userID: userID) { playlistID, error in
                                    if error == nil {
                                        completion(playlistID, nil)
                                    } else {
                                        completion(nil, error)
                                    }
                                }
                            }
                            case let .failure(error): completion(nil, error)
                            }
                        }
                    } else {
                        // Handle when a song isn't found (just keep searching)
                        print("Had an issue searching for \(track?.key) by \(track?.value)")
                        self.addTracksToPlaylist(trackList: tempTrackList, playlistID: playlistID, userID: userID) { playlistID, error in
                            if error == nil {
                                completion(playlistID, nil)
                            } else {
                                completion(nil, error)
                            }
                        }
                    }
                }
        }
    }

    /// Gets the track list for the shared playlist
    ///
    /// - Parameters:
    ///   - link: link to the playlist
    ///   - completion: function to handle the playlist
    func getTrackList(link: String, completion: @escaping ([String: String]?, String?, Error?) -> Void) {
        let playlistID = getPlaylistID(link: link)

        login { token, error in
            if error != nil {
                completion(nil, nil, error)
            } else {
                let headers: HTTPHeaders = ["Authorization": "Bearer \(token!)"]

                // Request the playlist data
                Alamofire.request("https://api.spotify.com/v1/playlists/\(playlistID)", method: .get, headers: headers)
                    .validate()
                    .responseJSON { response in

                        switch response.result {
                        case .success: do {
                            let playlistData = JSON(response.result.value!)
                            let playlistName = playlistData["name"].stringValue

                            // Request the playlist's tracks
                            Alamofire.request("https://api.spotify.com/v1/playlists/\(playlistID)/tracks", headers: headers)
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
    private func getPlaylistID(link: String) -> String {
        return String(link.components(separatedBy: "/playlist/")[1].split(separator: "?")[0])
    }
}

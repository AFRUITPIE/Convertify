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
    var serviceName: String = "Spotify"

    private let token: String?

    init(token: String?) {
        self.token = token
    }

    /// Add the playlist to Spotify
    ///
    /// - Parameters:
    ///   - trackList: list of tracks to add, [Song, Artist]
    ///   - playlistName: Name of the playlist
    ///   - completion: what to do with the link to the playlist after it's done
    func addPlaylist(trackList: [String: String], playlistName: String, completion: @escaping (String?, [String], Error?) -> Void) {
        // FIXME: This sure looks like the arrow anti-pattern to me

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
                                                 failedTracks: [],
                                                 playlistID: playlistID ?? "",
                                                 userID: id ?? "") { playlistLink, failedTracks, error in
                            if error == nil {
                                completion("https://open.spotify.com/playlist/\(playlistLink ?? "")", failedTracks, error)
                            } else {
                                // Something has gone wrong with adding the songs to the playlist
                                completion(nil, failedTracks, error)
                            }
                        }
                    } else {
                        // Something has gone wrong with creating the playlist
                        completion(nil, [], error)
                    }
                }
            } else {
                // Something has gone wrong with getting the user's ID
                completion(nil, [], error)
            }
        }
    }

    /// Gets ID of user
    ///
    /// - Parameters:
    ///   - userToken: user's token
    ///   - completion: what to do with user id
    private func getID(userToken: String, completion: @escaping (String?, Error?) -> Void) {
        let headers: HTTPHeaders = ["Authorization": "Bearer \(userToken)"]

        var urlComponents: URLComponents {
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "api.spotify.com"
            urlComponents.path = "/v1/me"
            return urlComponents
        }

        guard let url = urlComponents.url else {
            completion(nil, MusicSearcherErrors.invalidLinkFormatError)
            return
        }

        Alamofire.request(url, headers: headers).validate().responseJSON { response in
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
        var urlComponents: URLComponents {
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "api.spotify.com"
            urlComponents.path = "/v1/users/\(userID)/playlists/"
            return urlComponents
        }

        guard let url = urlComponents.url else {
            completion(nil, MusicSearcherErrors.invalidLinkFormatError)
            return
        }

        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
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
    private func addTracksToPlaylist(trackList: [String: String], failedTracks: [String], playlistID: String, userID: String, completion: @escaping (String?, [String], Error?) -> Void) {
        if trackList.isEmpty {
            completion(playlistID, [], nil)
        } else {
            var tempTrackList = trackList
            let track = tempTrackList.popFirst()

            // Get the Spotify's track ID
            SpotifySearcher(token: token ?? "")
                .search(name: "\(track?.key ?? "") \(track?.value ?? "")", type: "track") { trackLink, error in
                    if error == nil {
                        // Create a request for adding the track ID to the playlist
                        let trackID = String(trackLink!.split(separator: "/").last!)

                        let headers: HTTPHeaders = ["Authorization": "Bearer \(self.token ?? "")"]
                        let parameters: Parameters = ["uris": ["spotify:track:\(trackID)"]]

                        var urlComponents: URLComponents {
                            var urlComponents = URLComponents()
                            urlComponents.scheme = "https"
                            urlComponents.host = "api.spotify.com"
                            urlComponents.path = "/v1/playlists/\(playlistID)/tracks"
                            return urlComponents
                        }

                        guard let url = urlComponents.url else {
                            completion(nil, [], MusicSearcherErrors.invalidLinkFormatError)
                            return
                        }

                        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
                            switch response.result {
                            case .success: do {
                                // Recursively add the rest of the tracks to the playlist
                                self.addTracksToPlaylist(trackList: tempTrackList, failedTracks: failedTracks, playlistID: playlistID, userID: userID) { playlistID, failedTracks, error in
                                    if error == nil {
                                        completion(playlistID, failedTracks, nil)
                                    } else {
                                        completion(nil, failedTracks, error)
                                    }
                                }
                            }
                            case let .failure(error): completion(nil, failedTracks, error)
                            }
                        }
                    } else {
                        // Handle when a song isn't found (just keep searching)
                        var failedTracks = failedTracks
                        failedTracks.append("\(track?.key ?? "") by \(track?.value ?? "")") // ???
                        self.addTracksToPlaylist(trackList: tempTrackList, failedTracks: failedTracks, playlistID: playlistID, userID: userID) { playlistID, failedTracks, error in
                            completion(playlistID, failedTracks, error)
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

        SpotifySearcher.login { token, error in
            if error != nil {
                completion(nil, nil, error)
            } else {
                let headers: HTTPHeaders = ["Authorization": "Bearer \(token!)"]

                // Request the playlist data
                var urlComponents: URLComponents {
                    var urlComponents = URLComponents()
                    urlComponents.scheme = "https"
                    urlComponents.host = "api.spotify.com"
                    urlComponents.path = "/v1/playlists/\(playlistID)"
                    return urlComponents
                }

                guard let url = urlComponents.url else {
                    completion(nil, nil, MusicSearcherErrors.invalidLinkFormatError)
                    return
                }

                Alamofire.request(url, method: .get, headers: headers)
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

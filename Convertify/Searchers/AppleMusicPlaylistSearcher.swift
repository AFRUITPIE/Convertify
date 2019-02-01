//
//  AppleMusicPlaylistSearcher.swift
//  Convertify
//
//  Created by Hayden Hong on 1/24/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation
import StoreKit
import SwiftyJSON

class AppleMusicPlaylistSearcher: PlaylistSearcher {
    private let token: String = Auth.appleMusicKey
    private var storefront: String = "us"
    private var playlistID: String?

    /// Gets the track list from a given playlist
    ///
    /// - Parameters:
    ///   - link: playlist link
    ///   - completion: what to run when the track list is completed
    func getTrackList(link: String, completion: @escaping ([String: String]?, String?, Error?) -> Void) {
        parseLinkData(link: link)

        let headers = ["Authorization": "Bearer \(self.token)"]
        Alamofire.request("https://api.music.apple.com/v1/catalog/us/playlists/\(playlistID ?? "")", headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)
                    let playlistName = data["data"][0]["name"].stringValue

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

                    // Run completion with the finished track list
                    completion(trackList, playlistName, nil)
                }

                case let .failure(error): do {
                    completion(nil, nil, error)
                }
                }
            }
    }

    /// Adds a track list to an Apple Music user's playlists as a new playlist
    ///
    /// - Parameters:
    ///   - trackList: list of songs to add to a new playlist
    ///   - completion: what to do when the playlist is added
    func addPlaylist(trackList: [String: String], playlistName: String, completion: @escaping (String?, Error?) -> Void) {
        // Convert the playlist
        getConvertedPlaylist(trackList: trackList, playlistName: playlistName) { playlist in

            // Ensure access to user's Apple Apple Music library
            SKCloudServiceController.requestAuthorization() { authorizationStatus in
                switch authorizationStatus {
                case .authorized: do {
                    // Get Music User Token
                    SKCloudServiceController().requestUserToken(forDeveloperToken: Auth.appleMusicKey) { musicUserToken, error in

                        let parameters: Parameters = [
                            "attributes": playlist.attributes,
                            "relationships": [
                                "tracks": [
                                    "data": playlist.trackList,
                                ],
                            ],
                        ]

                        let headers: HTTPHeaders = ["Music-User-Token": musicUserToken ?? "", "Authorization": "Bearer \(Auth.appleMusicKey)"]

                        if error == nil {
                            // Add the playlist to the user's account
                            Alamofire.request("https://api.music.apple.com/v1/me/library/playlists", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                                .validate()
                                .responseJSON { response in
                                    switch response.result {
                                    case .success: do {
                                        let data = JSON(response.result.value!)
                                        let id = data["data"][0]["id"]
                                        let link = "https://itunes.apple.com/us/playlist/\(playlistName.replacingOccurrences(of: " ", with: "-").lowercased())/\(id)"
                                        completion(link, nil)
                                    }
                                    case let .failure(error): do { completion(nil, error) }
                                    }
                                }
                        } else {
                            completion(nil, error)
                        }
                    }
                }
                case .notDetermined: do { print("uhhh") }
                case .denied: do { print("uhhh") }
                case .restricted: do { print("uhhh") }
                }
            }
        }
    }

    /// Convert the playlist from the [Song: Artist] list to an array of AppleMusicPlaylistItems
    ///
    /// - Parameters:
    ///   - trackList: list of [Song: Artist], probably from Spotify
    ///   - completion: what to do with the completed playlist with IDs
    private func getConvertedPlaylist(trackList: [String: String], playlistName: String,
                                      completion: @escaping (AppleMusicPlaylist) -> Void) {
        let appleMusic: MusicSearcher = appleMusicSearcher()

        getConvertedPlaylistHelper(trackList: trackList,
                                   playlist: AppleMusicPlaylist(playlistName: playlistName),
                                   appleMusic: appleMusic) { playlist in
            completion(playlist)
        }
    }

    /// Recursive helper for making the tracklist
    ///
    /// - Parameters:
    ///   - trackList: list of [song: artist]
    ///   - playlist: playlist to be added to
    ///   - appleMusic: apple music searcher
    ///   - completion: what to run when complete playlist is done
    private func getConvertedPlaylistHelper(trackList: [String: String],
                                            playlist: AppleMusicPlaylist,
                                            appleMusic: MusicSearcher,
                                            completion: @escaping (AppleMusicPlaylist) -> Void) {
        // Base case, stop adding to the playlist if the tracklist is empty
        if trackList.isEmpty {
            completion(playlist)
            return
        }

        // Get the current track with a mutable temp track list
        var tempTrackList = trackList
        let currentTrack = tempTrackList.popFirst()

        // Search for the ID of the song
        appleMusic.search(name: "\(currentTrack?.key ?? "") \(currentTrack?.value ?? "")", type: "song") { error in
            var tempPlaylist = playlist

            // Report errors or add to the current playlist
            if error != nil {
                print("Had trouble finding \(currentTrack?.key ?? "") by \(currentTrack?.value ?? "")")
            } else {
                let id = String(appleMusic.url!.components(separatedBy: "?i=")[1])
                tempPlaylist.addTrack(id: id)
            }

            // Recursively keep searching
            self.getConvertedPlaylistHelper(trackList: tempTrackList, playlist: tempPlaylist, appleMusic: appleMusic, completion: completion)
        }
    }

    /// Parses Apple Music link data
    ///
    /// - Parameter link: Apple Music link to parse from
    private func parseLinkData(link: String) {
        playlistID = String(link.components(separatedBy: "/playlist/")[1]
            .split(separator: "/")[1])

        storefront = String(link.components(separatedBy: "https://itunes.apple.com/")[1]
            .split(separator: "/")[0])
    }
}

/// Framework of an Apple Music Playlist
private struct AppleMusicPlaylist {
    var trackList: [[String: String]]
    var attributes: [String: String]

    init(playlistName: String?) {
        trackList = []
        attributes = ["name": playlistName ?? "New Playlist",
                      "description": "Created with Convertify for iOS"]
    }

    mutating func addTrack(id: String) {
        trackList.append(["id": id, "type": "songs"])
    }
}

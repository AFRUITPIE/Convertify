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

    /// Gets the track list from a given playlist
    ///
    /// - Parameters:
    ///   - link: playlist link
    ///   - completion: what to run when the track list is completed
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

                    // Run completion with the finished track list
                    completion(trackList, nil)
                }

                case let .failure(error): do {
                    completion(nil, error)
                }
                }
            }
    }

    /// Adds a track list to an Apple Music user's playlists as a new playlist
    ///
    /// - Parameters:
    ///   - trackList: list of songs to add to a new playlist
    ///   - completion: what to do when the playlist is added
    func addPlaylist(trackList: [String: String], completion: @escaping (Error?) -> Void) {
        getConvertedPlaylist(trackList: trackList) { playlist in
            print(playlist)
            // TODO: Actually add this to the playlist lol

            // TODO: this won't always be nil because errors will happen
            completion(nil)
        }
    }

    /// Convert the playlist from the [Song: Artist] list to an array of AppleMusicPlaylistItems
    ///
    /// - Parameters:
    ///   - trackList: list of [Song: Artist], probably from Spotify
    ///   - completion: what to do with the completed playlist with IDs
    private func getConvertedPlaylist(trackList: [String: String],
                                      completion: @escaping ([AppleMusicPlaylistItem]) -> Void) {
        let appleMusic: MusicSearcher = appleMusicSearcher()

        getConvertedPlaylistHelper(trackList: trackList, playlist: [], appleMusic: appleMusic) { playlist in
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
                                            playlist: [AppleMusicPlaylistItem],
                                            appleMusic: MusicSearcher,
                                            completion: @escaping ([AppleMusicPlaylistItem]) -> Void) {
        // Base case, stop adding to the playlist if the tracklist is empty
        if trackList.isEmpty {
            completion(playlist)
            return
        }

        // Get the current track with a mutable temp track list and playlist
        var tempTrackList = trackList
        var tempPlaylist = playlist
        let currentTrack = tempTrackList.popFirst()

        // Search for the ID of the song
        appleMusic.search(name: "\(currentTrack?.key ?? "") \(currentTrack?.value ?? "")", type: "song") { error in

            // Report errors or add to the current playlist
            if error != nil {
                print("Had trouble finding \(currentTrack?.key ?? "") by \(currentTrack?.value ?? "")")
            } else {
                let id = String(appleMusic.url!.components(separatedBy: "?i=")[1])
                tempPlaylist.append(AppleMusicPlaylistItem(id: id))
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

/// Class for creating Apple Music playlists
private class AppleMusicPlaylistItem {
    let id: String
    let type: String = "songs"
    init(id: String) {
        self.id = id
    }
}

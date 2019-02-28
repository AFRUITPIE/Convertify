//
//  PlaylistSearcher.swift
//  Convertify
//
//  Created by Hayden Hong on 1/24/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation

protocol PlaylistSearcher {
    // The name of the service
    var serviceName: String { get }

    /// Gets a list of the tracks of a playlist from a given url
    ///
    /// - Parameters:
    ///   - link: url of the playlist
    ///   - completion: what to do with the tacklist: ([track name: artist name], name of playlist, error)
    func getTrackList(link: String, completion: @escaping ([String: String]?, String?, Error?) -> Void)

    /// Add a playlist to the source
    ///
    /// - Parameters:
    ///   - trackList: list of tracks and artists to add, [TrackName: Artist]
    ///   - playlistName: Name of the playlist
    ///   - completion: what to do with the playlist once it is added (link to new playlist, list of songs that failed to add, errors)
    func addPlaylist(trackList: [String: String], playlistName: String, completion: @escaping (String?, [String], Error?) -> Void)
}

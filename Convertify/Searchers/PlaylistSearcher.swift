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
    func getTrackList(link: String, completion: @escaping ([String: String]?, String?, Error?) -> Void)
    func addPlaylist(trackList: [String: String], playlistName: String, completion: @escaping (String?, Error?) -> Void)
}

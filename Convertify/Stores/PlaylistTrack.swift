//
//  PlaylistTrack.swift
//  Convertify
//
//  Created by Hayden Hong on 11/5/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Foundation

class PlaylistTrack {
    public private(set) var trackName: String
    public private(set) var artistName: String
    public private(set) var trackURL: String?
    public private(set) var albumArt: String?
    public var id: String?
    init(trackName: String, artistName: String, trackURL: String?, albumArt: String?) {
        self.trackName = trackName
        self.artistName = artistName
        self.trackURL = trackURL
        self.albumArt = albumArt
    }
}

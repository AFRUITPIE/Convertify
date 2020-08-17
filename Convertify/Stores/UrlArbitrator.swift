//
//  UrlArbitrator.swift
//  Convertify
//
//  Created by Hayden Hong on 8/16/20.
//  Copyright © 2020 Hayden Hong. All rights reserved.
//

import Foundation

public class UrlArbitrator {
    private let url: URL?

    public init(for url: String) {
        self.url = URL(string: url)
    }

    func isPlaylist() -> Bool {
        return false
    }

    var service: MusicService {
        guard let url = url else {
            return .none
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .none
        }

        switch components.host {
        case "music.apple.com":
            return .appleMusic
        case "itunes.apple.com":
            return .appleMusic
        case "open.spotify.com":
            return .spotify
        default:
            return .none
        }
    }

    var musicType: MusicType {
        guard let url = url else {
            return .other
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .other
        }

        let path = components.path.split(separator: "/")

        for part in path {
            switch part {
            case "playlist":
                return .playlist
            case "artist":
                return .artist
            case "track":
                return .track
            case "album":
                do {
                    // Handle Apple Music's stupid album -> track url format
                    if service == .appleMusic {
                        guard let queryItems = components.queryItems else {
                            return .album
                        }
                        for item in queryItems {
                            if item.name == "i" {
                                return .track
                            }
                        }
                    }

                    return .album
                }
            case "station":
                return .station
            default: break
            }
        }

        return .other
    }

    var id: String {
        guard let url = url else {
            return ""
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return ""
        }
        let path = components.path.split(separator: "/")
        return String(path.last ?? "")
    }

    enum MusicType {
        case playlist
        case track
        case album
        case artist
        case station
        case other
    }

    enum MusicService {
        case spotify
        case appleMusic
        case none
    }
}

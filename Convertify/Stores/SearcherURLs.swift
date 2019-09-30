//
//  SearcherURLs.swift
//  Convertify
//
//  Created by Hayden Hong on 8/15/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Foundation

enum SearcherURL {
    static let spotify = "https://open.spotify.com/.*/\\w{22}\\b((\\?)si=\\w{22}\\b|)"
    static let appleMusic = "https://(itunes|music).apple.com/\\w{2}\\b/.*/.*/\\w{10}\\b((\\?)i=\\w{10}\\b|)"

    static let playlist = "https://open.spotify.com/playlist/.*|https://(itunes|music).apple.com/\\w{2}\\b/playlist/.*/.*"
}

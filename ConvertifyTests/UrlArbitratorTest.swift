//
//  UrlArbitratorTest.swift
//  ConvertifyTests
//
//  Created by Hayden Hong on 8/16/20.
//  Copyright © 2020 Hayden Hong. All rights reserved.
//

@testable import Convertify
import Foundation
import UIKit
import XCTest

class UrlArbitratorTest: XCTestCase {
    override func setUp() {
        print("Hello world!")
    }

    func testAppleMusicPlaylistUrl() {
        let arbitrator = UrlArbitrator(for: "https://music.apple.com/us/playlist/dijkstra/pl.u-GgA5zBBfZEebME")

        XCTAssert(arbitrator.service == .appleMusic)
        XCTAssert(arbitrator.musicType == .playlist)
    }

    func testSpotifyPlaylistUrl() {
        let arbitrator = UrlArbitrator(for: "https://open.spotify.com/playlist/37i9dQZF1E38HWtKaKmV77?si=AIPSKWASRzG6bOh3fJgxOg")

        XCTAssert(arbitrator.service == .spotify)
        XCTAssert(arbitrator.musicType == .playlist)
    }
}

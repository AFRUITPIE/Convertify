//
//  PlaylistTests.swift
//  ConvertifyTests
//
//  Created by Hayden Hong on 1/24/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Foundation

import UIKit
import XCTest

class PlaylistTests: XCTestCase {
    // var spotify: PlaylistSearcher!
    var appleMusic: PlaylistSearcher!

    override func setUp() {
        appleMusic = AppleMusicPlaylistSearcher()
    }

    func testGetAppleMusicPlaylistTracks() {
        let expectation = self.expectation(description: "Get the tracks from the playlist")

        appleMusic.getTrackList(link: "https://itunes.apple.com/us/playlist/test/pl.u-KVXBD8vFZeqz7e") { trackList, error in
            XCTAssertNil(error)
            XCTAssertNotNil(trackList)

            let comparisonTrackList = ["Tweakin'": "Vince Staples",
                                       "Take Me Away (feat. Syd)": "Daniel Caesar"]
            XCTAssertEqual(trackList, comparisonTrackList)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
}

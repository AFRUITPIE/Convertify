//
//  RegexTests.swift
//  Convertify
//
//  Created by Hayden Hong on 11/18/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Foundation
import UIKit
import XCTest

class RegexTests: XCTestCase {
    public static var appleMusic = SearcherURL.appleMusic

    // MARK: Playlist regex

    func regexTest(of: String, _ link: String) {
        XCTAssertNotNil(link.range(of: of, options: [.regularExpression, .anchored]))
    }

    func testAppleMusicValidLinkUserPlaylist() {
        regexTest(of: .appleMusic, "")
    }

    func testAppleMusicValidLinkPublicPlaylist() {}

    func testAppleMusicInvalidLinkShortID() {}

    func testAppleMusicInvalidLinkLongID() {}

    func testSpotifyValidLinkWithUserID() {}

    func testSpotifyValidLinkWithoutUserID() {}

    func testSpotifyInvalidLinkShortID() {}

    func testSpotifyInvalidLinkLongID() {}

    func testSpotifyInvalidLinkShortUserID() {}

    func testSpotifyInvalidLinkLongUserID() {}

    // MARK: All other regex

    func testAppleMusicValidTrack() {}

    func testAppleMusicValidAlbum() {}

    func testAppleMusicValidArtist() {}

    func testAppleMusicInalidTrack() {}

    func testAppleMusicInvalidAlbum() {}

    func testAppleMusicInvalidArtist() {}
}

/// This extension cuts down on a lot of boilerplate code
extension String {
    public static let appleMusic = SearcherURL.appleMusic
    public static let spotify = SearcherURL.spotify
    public static let playlist = SearcherURL.playlist
}

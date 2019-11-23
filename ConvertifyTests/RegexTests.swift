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

    private func regexTestPass(of: String, _ link: String) {
        XCTAssertNotNil(link.range(of: of, options: [.regularExpression, .anchored]))
    }

    private func regexTestFail(of: String, _ link: String) {
        XCTAssertNil(link.range(of: of, options: [.regularExpression, .anchored]))
    }

    func testAppleMusicValidLinkUserPlaylist() {
        regexTestPass(of: .playlist, "https://music.apple.com/us/playlist/asdf/pl.u-asdfk3xT5RvWeR")
    }

    func testAppleMusicValidLinkPublicPlaylist() {
        regexTestPass(of: .playlist, "https://music.apple.com/us/playlist/heard-in-apple-ads/pl.b28c3a5975b04436b42680595f6983ad")
    }

    func testAppleMusicInvalidLinkShortID() {
        regexTestFail(of: .playlist, "https://music.apple.com/us/playlist/asdf/pl.u-asdfk3xT5RvWe")
        regexTestFail(of: .playlist, "https://music.apple.com/us/playlist/heard-in-apple-ads/pl.b28c3a5975b04436b42680595f6983a")
    }

    func testAppleMusicInvalidLinkLongID() {
        // User playlist
        regexTestFail(of: .playlist, "https://music.apple.com/us/playlist/asdf/pl.u-asdfk3xT5RvWeee")

        // Public playlist
        regexTestFail(of: .playlist, "https://music.apple.com/us/playlist/heard-in-apple-ads/pl.b28c3a5975b04436b42680595f6983aaa")
    }

    func testSpotifyValidLinkWithUserID() {
        regexTestPass(of: .playlist, "https://open.spotify.com/playlist/37i9dQZF1DXdPec7aLTmlC?si=NmBWf2B5SLegFyBm5xTOhA")
    }

    func testSpotifyValidLinkWithoutUserID() {
        regexTestPass(of: .playlist, "https://open.spotify.com/playlist/37i9dQZF1DXdPec7aLTmlC")
    }

    func testSpotifyInvalidLinkShortID() {
        regexTestFail(of: .playlist, "https://open.spotify.com/playlist/37i9dQZF1DXdPec7aLTml")
    }

    func testSpotifyInvalidLinkLongID() {
        regexTestFail(of: .playlist, "https://open.spotify.com/playlist/37i9dQZF1DXdPec7aLTmlll")
    }

    func testSpotifyInvalidLinkShortUserID() {
        regexTestFail(of: .playlist, "https://open.spotify.com/playlist/37i9dQZF1DXdPec7aLTmlC?si=NmBWf2B5SLegFyBm5xTOh")
    }

    func testSpotifyInvalidLinkLongUserID() {
        regexTestFail(of: .playlist, "https://open.spotify.com/playlist/37i9dQZF1DXdPec7aLTmlC?si=NmBWf2B5SLegFyBm5xTOhhh")
    }

    // MARK: All other regex

    func testAppleMusicValidTrack() {
        regexTestPass(of: .appleMusic, "https://itunes.apple.com/us/album/hurt-feelings/1408996052?i=1408996054")
    }

    func testAppleMusicValidAlbum() {
        regexTestPass(of: .appleMusic, "https://itunes.apple.com/us/album/blonde/1146195596")
    }

    func testAppleMusicValidArtist() {
        regexTestPass(of: .appleMusic, "https://itunes.apple.com/us/artist/saba/1140260329")
    }

    func testAppleMusicInvalidTrack() {
        regexTestFail(of: .appleMusic, "https://itunes.apple.com/us/album/hurt-feelings/140899605?i=140899605")
    }

    func testAppleMusicInvalidAlbum() {
        regexTestFail(of: .appleMusic, "https://itunes.apple.com/us/album/blonde/114619559")
    }

    func testAppleMusicInvalidArtist() {
        regexTestFail(of: .appleMusic, "https://itunes.apple.com/us/artist/saba/114026032")
    }

    func testSpotifyValidTrack() {
        regexTestPass(of: .spotify, "https://open.spotify.com/track/2TVxnKdb3tqe1nhQWwwZCO")
    }

    func testSpotifyValidAlbum() {
        regexTestPass(of: .spotify, "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM0")
    }

    func testSpotifyValidArtist() {
        regexTestPass(of: .spotify, "https://open.spotify.com/artist/70cRZdQywnSFp9pnc2WTCE")
    }

    func testSpotifyInvalidTrack() {
        regexTestFail(of: .spotify, "https://open.spotify.com/track/2TVxnKdb3tqe1nhQWwwZC")
    }

    func testSpotifyInvalidArtist() {
        regexTestFail(of: .spotify, "https://open.spotify.com/artist/70cRZdQywnSFp9pnc2WTC")
    }

    func testSpotifyInvalidAlbum() {
        regexTestFail(of: .spotify, "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM")
    }
}

/// This extension cuts down on a lot of boilerplate code
extension String {
    public static let appleMusic = SearcherURL.appleMusic
    public static let spotify = SearcherURL.spotify
    public static let playlist = SearcherURL.playlist
}

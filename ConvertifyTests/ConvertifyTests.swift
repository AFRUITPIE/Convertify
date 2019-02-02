//
//  ConvertifyTests.swift
//  ConvertifyTests
//
//  Created by Hayden Hong on 8/10/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import UIKit
import XCTest

class ConvertifyTests: XCTestCase {
    var spotify: MusicSearcher!
    var appleMusic: MusicSearcher!

    override func setUp() {
        UIPasteboard.general.string = ""

        let expectation = self.expectation(description: "Login spotify and Apple Music")

        if spotify == nil {
            spotify = spotifySearcher(completion: { error in
                if error == nil {
                    self.appleMusic = appleMusicSearcher()
                    expectation.fulfill()
                } else {
                    XCTFail()
                }
            })
        } else {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    /// Test searching across services
    ///
    /// - Parameters:
    ///   - link: link to test
    ///   - name: name of asset
    ///   - type: type of asset
    ///   - artist: artist of asset
    private func testLink(link: String, name: String, type: String, artist: String?, source: MusicSearcher, destination: MusicSearcher) {
        let expectation = self.expectation(description: "HTTP request for searching")

        source.search(link: link) { compareType, compareName, compareArtist, error in
            XCTAssertNil(error)

            // Verify data from source is correct
            XCTAssertEqual(compareName?.lowercased() ?? nil, name.lowercased())
            XCTAssertEqual(compareType?.lowercased() ?? nil, type.lowercased())
            XCTAssertEqual(compareArtist?.lowercased(), artist?.lowercased() ?? nil)

            // Verify data from destination is correct
            destination.search(name: compareName ?? "", type: compareType ?? "") { destinationLink, error in
                XCTAssertNil(error)

                expectation.fulfill()

                // Check destination's data
                XCTAssertNotNil(destinationLink)
            }
        }
    }

    func testSpotifyLinkArtist() {
        testLink(link: SpotifyLinks.Artist.rawValue,
                 name: "Vince Staples",
                 type: "artist",
                 artist: nil,
                 source: spotify,
                 destination: appleMusic)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSpotifyLinkAlbum() {
        testLink(link: SpotifyLinks.Album.rawValue,
                 name: "Freudian",
                 type: "album",
                 artist: "Daniel Caesar",
                 source: spotify,
                 destination: appleMusic)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSpotifyLinkSong() {
        testLink(link: SpotifyLinks.Song.rawValue,
                 name: "Hurt Feelings",
                 type: "track",
                 artist: "Mac Miller",
                 source: spotify,
                 destination: appleMusic)
        waitForExpectations(timeout: 10, handler: nil) }

    func testAppleLinkAlbum() {
        testLink(link: AppleMusicLinks.Album.rawValue,
                 name: "Redemption",
                 type: "Album",
                 artist: "Jay Rock",
                 source: appleMusic,
                 destination: spotify)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppleLinkArtist() {
        testLink(link: AppleMusicLinks.Artist.rawValue,
                 name: "Saba",
                 type: "Artist",
                 artist: nil,
                 source: appleMusic,
                 destination: spotify)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppleLinkSong() {
        testLink(link: AppleMusicLinks.Song.rawValue,
                 name: "Room in Here (feat. The Game & Sonyae Elise)",
                 type: "song",
                 artist: "Anderson .Paak",
                 source: appleMusic,
                 destination: spotify)
        waitForExpectations(timeout: 1000, handler: nil)
    }

    /// Tests involving searching with words

    private func testSpotifyQuery(name: String, type: String, url: String) {
        let expectation = self.expectation(description: "Testing Spotify query for url: \(url)")
        spotify.search(name: name, type: type) { destinationLink, error in
            XCTAssertNil(error)
            XCTAssertEqual(destinationLink, url)
            expectation.fulfill()
        }
    }

    private func testAppleMusicQuery(name: String, type: String, url: String) {
        let expectation = self.expectation(description: "Testing Apple Music query for url: \(url)")
        appleMusic.search(name: name, type: type) { destinationLink, error in
            XCTAssertNil(error)
            XCTAssertEqual(destinationLink, url)
            expectation.fulfill()
        }
    }

    func testSpotifyQueryAlbum() {
        testSpotifyQuery(name: "Freudian",
                         type: "album",
                         url: "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM0")
        waitForExpectations(timeout: 10, handler: nil) }

    func testSpotifyQueryArtist() {
        testSpotifyQuery(name: "Simon & Garfunkel",
                         type: "artist",
                         url: "https://open.spotify.com/artist/70cRZdQywnSFp9pnc2WTCE")
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSpotifyQuerySong() {
        testSpotifyQuery(name: "Tiny Dancer",
                         type: "song",
                         url: "https://open.spotify.com/track/2TVxnKdb3tqe1nhQWwwZCO")
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppleMusicError() {
        let am = appleMusicSearcher()
        am.search(name: "THERE IS NO POSSIBLE WAY THIS WILL EVER BE AN ALBUM NAME", type: "album", completion: { _, error in
            XCTAssertNotNil(error)
        })
    }

    func testAppleQueryAlbum() {
        testAppleMusicQuery(name: "Blonde",
                            type: "album",
                            url: "https://itunes.apple.com/us/album/blonde/1146195596")
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppleQueryArtist() {
        testAppleMusicQuery(name: "Saba",
                            type: "artist",
                            url: AppleMusicLinks.Artist.rawValue)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppleQuerySong() {
        testAppleMusicQuery(name: "Room in Here (feat. The Game & Sonyae Elise)",
                            type: "track",
                            url: AppleMusicLinks.Song.rawValue)
        waitForExpectations(timeout: 10, handler: nil)
    }

    private func testErrorUrl(url: String, searcher: MusicSearcher) {
        let expectation = self.expectation(description: "Testing failure on incorrect URL")

        searcher.search(link: url) { _, _, _, error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("timeout errored: \(error)")
            }
        }
    }

    private func testErrorName(name: String, searcher: MusicSearcher) {
        let expectation = self.expectation(description: "Testing failure on incorrect name")

        searcher.search(name: name, type: "album") { _, error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("timeout errored: \(error)")
            }
        }
    }
}

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

        waitForExpectations(timeout: 5, handler: nil)
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

        source.search(link: link)?.responseJSON { response in
            switch response.result {
            case .success: do {
                // Verify data from source is correct
                XCTAssertEqual(source.name?.lowercased() ?? nil, name.lowercased())
                XCTAssertEqual(source.type?.lowercased() ?? nil, type.lowercased())
                XCTAssertEqual(source.artist?.lowercased(), artist?.lowercased() ?? nil)

                // Verify data from destination is correct
                destination.search(name: source.name ?? "", type: source.type ?? "", completion: { error in
                    if error == nil {
                        // Searching was successful both times, fulfill the expectation
                        expectation.fulfill()

                        // Check destination's data
                        XCTAssertNotNil(destination.url)
                    }
                })
            }
            case .failure: do {
                XCTFail()
            }
            }
        }
    }

    func testSpotifyLinkArtist() {
        testLink(link: "https://open.spotify.com/artist/68kEuyFKyqrdQQLLsmiatm?si=149GzNXcSZ2izP9mRCpCuQ",
                 name: "Vince Staples",
                 type: "artist",
                 artist: nil,
                 source: spotify,
                 destination: appleMusic)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSpotifyLinkAlbum() {
        testLink(link: "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM0?si=c0eZiEk9RpS15Y7vYlcqGA",
                 name: "Freudian",
                 type: "album",
                 artist: "Daniel Caesar",
                 source: spotify,
                 destination: appleMusic)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSpotifyLinkSong() {
        testLink(link: "https://open.spotify.com/track/5p7GiBZNL1afJJDUrOA6C8?si=TstqlH0ZSxOkp436_-gl3A",
                 name: "Hurt Feelings",
                 type: "track",
                 artist: "Mac Miller",
                 source: spotify,
                 destination: appleMusic)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppleLinkAlbum() {
        testLink(link: "https://itunes.apple.com/us/artist/saba/1140260329",
                 name: "Saba",
                 type: "Artist",
                 artist: nil,
                 source: appleMusic,
                 destination: spotify)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppleLinkArtist() {
        testLink(link: "https://itunes.apple.com/us/album/redemption/1395741818",
                 name: "Redemption",
                 type: "Album",
                 artist: "Jay Rock",
                 source: appleMusic,
                 destination: spotify)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppleLinkSong() {
        testLink(link: "https://itunes.apple.com/us/album/room-in-here-feat-the-game-sonyae-elise/1065681363?i=1065681767",
                 name: "Room in Here (feat. The Game & Sonyae Elise)",
                 type: "song",
                 artist: "Anderson .Paak",
                 source: appleMusic,
                 destination: spotify)
        waitForExpectations(timeout: 10, handler: nil)
    }

    /// Tests involving searching with words

    private func testSpotifyQuery(name: String, type: String, url: String) {
        let expectation = self.expectation(description: "Testing Spotify query for url: \(url)")
        spotify.search(name: name, type: type, completion: { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.spotify.url, url)
            expectation.fulfill()
        })
    }

    private func testAppleMusicQuery(name: String, type: String, url: String) {
        let expectation = self.expectation(description: "Testing Apple Music query for url: \(url)")
        appleMusic.search(name: name, type: type, completion: { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.appleMusic.url, url)
            expectation.fulfill()
        })
    }

    func testSpotifyError() {
        let expectation = self.expectation(description: "Spotify error")
        spotify.search(name: "THERE IS NO POSSIBLE WAY THIS WILL EVER BE AN ALBUM NAME", type: "album", completion: { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSpotifyQueryAlbum() {
        testSpotifyQuery(name: "Freudian",
                         type: "album",
                         url: "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM0")
        waitForExpectations(timeout: 10, handler: nil)
    }

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
        am.search(name: "THERE IS NO POSSIBLE WAY THIS WILL EVER BE AN ALBUM NAME", type: "album", completion: { error in
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
                            url: "https://itunes.apple.com/us/artist/saba/1140260329")
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppleQuerySong() {
        testAppleMusicQuery(name: "Hurt Feelings",
                            type: "track",
                            url: "https://itunes.apple.com/us/album/hurt-feelings/1408996052?i=1408996054")
        waitForExpectations(timeout: 10, handler: nil)
    }
}

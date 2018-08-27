//
//  ConvertifyTests.swift
//  ConvertifyTests
//
//  Created by Hayden Hong on 8/10/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import XCTest

class ConvertifyTests: XCTestCase {
    override func setUp() {}

    override func tearDown() {
        // Do nothing
    }

    /// Tests involving searching with links in Spotify
    private func testSpotifyLink(link: String, name: String, type: String, artist: String?) {
        let spt = spotifySearcher()
        spt.search(link: link)?.validate().responseJSON { _ in
            XCTAssertEqual(spt.name ?? nil, name)
            XCTAssertEqual(spt.type ?? nil, type)
            XCTAssertEqual(spt.artist, artist ?? nil)
        }
    }

    /// Tests involving searching with links in Apple Music
    private func testAppleMusicLink(link: String, name: String, type: String, artist: String?) {
        let am = appleMusicSearcher()
        am.search(link: link)?.validate().responseJSON { _ in
            XCTAssertEqual(am.name ?? nil, name)
            XCTAssertEqual(am.type ?? nil, type)
            XCTAssertEqual(am.artist, artist ?? nil)
        }
    }

    func testSpotifyLinkArtist() {
        testSpotifyLink(link: "https://open.spotify.com/artist/68kEuyFKyqrdQQLLsmiatm?si=149GzNXcSZ2izP9mRCpCuQ",
                        name: "Vince Staples",
                        type: "artist",
                        artist: nil)
    }

    func testSpotifyLinkAlbum() {
        testSpotifyLink(link: "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM0?si=c0eZiEk9RpS15Y7vYlcqGA",
                        name: "Freudian",
                        type: "album",
                        artist: "Daniel Caesar")
    }

    func testSpotifyLinkSong() {
        testSpotifyLink(link: "https://open.spotify.com/track/5p7GiBZNL1afJJDUrOA6C8?si=TstqlH0ZSxOkp436_-gl3A",
                        name: "Hurt Feelings",
                        type: "track",
                        artist: "Mac Miller")
    }

    func testAppleLinkAlbum() {
        testAppleMusicLink(link: "https://itunes.apple.com/us/artist/saba/1140260329",
                           name: "Saba",
                           type: "Artist",
                           artist: nil)
    }

    func testAppleLinkArtist() {
        testAppleMusicLink(link: "https://itunes.apple.com/us/album/redemption/1395741818",
                           name: "Redemption",
                           type: "Album",
                           artist: "Jay Rock")
    }

    func testAppleLinkSong() {
        testAppleMusicLink(link: "https://itunes.apple.com/us/album/come-down/1065681363?i=1065681770",
                           name: "Room in Here (feat. The Game & Sonyae Elise)",
                           type: "song",
                           artist: "Anderson .Paak")
    }

    /// Tests involving searching with words

    private func testSpotifyQuery(name: String, type: String, url: String) {
        let spt = spotifySearcher()
        spt.search(name: name, type: type).validate().responseJSON { _ in
            XCTAssertEqual(spt.url, url)
        }
    }

    private func testAppleMusicQuery(name: String, type: String, url: String) {
        let am = appleMusicSearcher()
        am.search(name: name, type: type).validate().responseJSON { _ in
            XCTAssertEqual(am.url, url)
        }
    }

    func testSpotifyQueryAlbum() {
        testSpotifyQuery(name: "Freudian",
                         type: "album",
                         url: "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM0")
    }

    func testSpotifyQueryArtist() {
        testSpotifyQuery(name: "Simon & Garfunkel",
                         type: "artist",
                         url: "https://open.spotify.com/artist/70cRZdQywnSFp9pnc2WTCE")
    }

    func testSpotifyQuerySong() {
        testSpotifyQuery(name: "Tiny Dancer",
                         type: "song",
                         url: "https://open.spotify.com/track/2TVxnKdb3tqe1nhQWwwZCO")
    }

    func testAppleQueryAlbum() {
        testAppleMusicQuery(name: "Blonde",
                            type: "album",
                            url: "https://itunes.apple.com/us/album/blonde/1146195596")
    }

    func testAppleQueryArtist() {
        testAppleMusicQuery(name: "Saba",
                            type: "artist",
                            url: "https://itunes.apple.com/us/artist/saba/1140260329")
    }

    func testAppleQuerySong() {
        testAppleMusicQuery(name: "Hurt Feelings",
                            type: "track",
                            url: "https://itunes.apple.com/us/album/hurt-feelings/1408996052?i=1408996054")
    }
}

//
//  ConvertifyUITests.swift
//  ConvertifyUITests
//
//  Created by Hayden Hong on 11/5/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import UIKit
import XCTest

class ConvertifyUITests: XCTestCase {
    var app: XCUIApplication!

    let appleMusicButton: String = "Open in Apple Music"
    let spotifyButton: String = "Open in Spotify"

    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
    }

    override func tearDown() {
        sleep(5)
        app.terminate()
    }

    private func testAppUI(labelName: String, buttonLabel: String) {
        app.launch()

        // Allow app to "think", process http requests
        sleep(5)

        // Ensure the label's text is correct
        XCTAssertNotNil(app.staticTexts.element(matching: .any, identifier: labelName).label)

        // Ensure the button is shown
        XCTAssertNotNil(app.buttons[buttonLabel])
        XCTAssertTrue(app.buttons[buttonLabel].isEnabled)
    }

    func testAppleMusicSearchArtist() {
        UIPasteboard.general.string = "https://itunes.apple.com/us/artist/saba/1140260329"
        testAppUI(labelName: "Saba", buttonLabel: spotifyButton)
    }

    func testAppleMusicSearchAlbum() {
        UIPasteboard.general.string = "https://itunes.apple.com/us/album/blonde/1146195596"
        testAppUI(labelName: "Blonde by Frank Ocean", buttonLabel: spotifyButton)
    }

    func testAppleMusicSearchSong() {
        UIPasteboard.general.string = "https://itunes.apple.com/us/album/hurt-feelings/1408996052?i=1408996054"
        testAppUI(labelName: "Hurt Feelings by Mac Miller", buttonLabel: spotifyButton)
    }

    func testSpotifyArtist() {
        UIPasteboard.general.string = "https://open.spotify.com/artist/70cRZdQywnSFp9pnc2WTCE"
        testAppUI(labelName: "Simon & Garfunkel", buttonLabel: appleMusicButton)
    }

    func testSpotifyAlbum() {
        UIPasteboard.general.string = "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM0"
        testAppUI(labelName: "Freudian by Daniel Caesar", buttonLabel: appleMusicButton)
    }

    func testSpotifySearchSong() {
        UIPasteboard.general.string = "https://open.spotify.com/track/2TVxnKdb3tqe1nhQWwwZCO"
        testAppUI(labelName: "Tiny Dancer by Elton John", buttonLabel: appleMusicButton)
    }
}

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
    let playlistError: String = "Playlist conversion coming soon 👀"
    let radioError: String = "I cannot convert radio stations ☹️"
    let noLinkError: String = "No Spotify or Apple Music link found in clipboard"

    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
    }

    override func tearDown() {
        // wait 5 seconds
        sleep(5)

        // close the app
        app.terminate()
    }

    /// Framework for testing the application's ui
    ///
    /// - Parameters:
    ///   - labelName: name of the label
    ///   - buttonLabel: name of the button
    ///   - buttonEnabled: whether or not the button should be clickable
    private func testAppUI(labelName: String, buttonLabel: String, buttonEnabled: Bool) {
        app.launch()

        // Allow app to "think", process http requests
        sleep(5)

        // Ensure the label's text is correct
        XCTAssertNotNil(app.staticTexts.element(matching: .any, identifier: labelName).label)

        // Ensure the button is shown
        XCTAssertNotNil(app.buttons[buttonLabel])
        XCTAssertEqual(app.buttons[buttonLabel].isEnabled, buttonEnabled)
    }

    /*

     Apple Music searches

     */

    func testAppleMusicSearchArtist() {
        UIPasteboard.general.string = "https://itunes.apple.com/us/artist/saba/1140260329"
        testAppUI(labelName: "Saba", buttonLabel: spotifyButton, buttonEnabled: true)
    }

    func testAppleMusicSearchAlbum() {
        UIPasteboard.general.string = "https://itunes.apple.com/us/album/blonde/1146195596"
        testAppUI(labelName: "Blonde by Frank Ocean", buttonLabel: spotifyButton, buttonEnabled: true)
    }

    func testAppleMusicSearchSong() {
        UIPasteboard.general.string = "https://itunes.apple.com/us/album/hurt-feelings/1408996052?i=1408996054"
        testAppUI(labelName: "Hurt Feelings by Mac Miller", buttonLabel: spotifyButton, buttonEnabled: true)
    }

    func testAppleMusicSearchStation() {
        UIPasteboard.general.string = "https://itunes.apple.com/us/station/under-the-covers-feat-emma-sameth/ra.1160002338"
        testAppUI(labelName: "Convertify", buttonLabel: radioError, buttonEnabled: false)
    }

    /*

     Spotify searches

     */

    func testSpotifyArtist() {
        UIPasteboard.general.string = "https://open.spotify.com/artist/70cRZdQywnSFp9pnc2WTCE"
        testAppUI(labelName: "Simon & Garfunkel", buttonLabel: appleMusicButton, buttonEnabled: true)
    }

    func testSpotifyAlbum() {
        UIPasteboard.general.string = "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM0"
        testAppUI(labelName: "Freudian by Daniel Caesar", buttonLabel: appleMusicButton, buttonEnabled: true)
    }

    func testSpotifySearchSong() {
        UIPasteboard.general.string = "https://open.spotify.com/track/2TVxnKdb3tqe1nhQWwwZCO"
        testAppUI(labelName: "Tiny Dancer by Elton John", buttonLabel: appleMusicButton, buttonEnabled: true)
    }

    /*

     Other errors here:

     */

    func testSearchNil() {
        // Nil the pasteboard
        UIPasteboard.general.items = []
        testAppUI(labelName: "Convertify", buttonLabel: noLinkError, buttonEnabled: false)
    }
}

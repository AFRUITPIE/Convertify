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

    /// Tests the app
    /// - Parameter link: link to type in
    /// - Parameter labelName: what the label should read
    /// - Parameter buttonLabel: what the button should read
    /// - Parameter buttonEnabled: whether or not the button is enabled
    private func testAppUI(link: String, labelName: String, buttonLabel: String, buttonEnabled: Bool) {
        app.launch()

        // Type it in
        let linkField: XCUIElement = app.textFields["Paste Spotify or Apple Music Link Here"]
        linkField.tap()
        linkField.typeText(link)

        // Allow app to "think" for a bit
        sleep(2)

        // Ensure the label's text is correct
        XCTAssertNotNil(app.staticTexts.element(matching: .any, identifier: labelName).label)

        // Ensure the button is shown
        XCTAssertNotNil(app.buttons[buttonLabel])
        XCTAssertEqual(app.buttons[buttonLabel].isEnabled, buttonEnabled)
    }

    // MARK: Apple Music searches

    func testAppleMusicSearchArtist() {
        testAppUI(link: "https://music.apple.com/us/artist/saba/1140260329", labelName: "Saba", buttonLabel: spotifyButton, buttonEnabled: true)
    }

    func testAppleMusicSearchAlbum() {
        testAppUI(link: "https://music.apple.com/us/album/blonde/1146195596", labelName: "Blonde by Frank Ocean", buttonLabel: spotifyButton, buttonEnabled: true)
    }

    func testAppleMusicSearchSong() {
        testAppUI(link: "https://music.apple.com/us/album/hurt-feelings/1408996052?i=1408996054", labelName: "Hurt Feelings by Mac Miller", buttonLabel: spotifyButton, buttonEnabled: true)
    }

    func testAppleMusicSearchStation() {
        testAppUI(link: "https://music.apple.com/us/station/everybody/ra.1494022983", labelName: "Convertify", buttonLabel: radioError, buttonEnabled: false)
    }

    // MARK: Spotify searches

    func testSpotifyArtist() {
        testAppUI(link: "https://open.spotify.com/artist/70cRZdQywnSFp9pnc2WTCE", labelName: "Simon & Garfunkel", buttonLabel: appleMusicButton, buttonEnabled: true)
    }

    func testSpotifyAlbum() {
        testAppUI(link: "https://open.spotify.com/album/3xybjP7r2VsWzwvDQipdM0", labelName: "Freudian by Daniel Caesar", buttonLabel: appleMusicButton, buttonEnabled: true)
    }

    func testSpotifySearchSong() {
        testAppUI(link: "https://open.spotify.com/track/2TVxnKdb3tqe1nhQWwwZCO", labelName: "Tiny Dancer by Elton John", buttonLabel: appleMusicButton, buttonEnabled: true)
    }
}

//
//  ViewController.swift
//  Convertify
//
//  Created by Hayden Hong on 8/7/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import Pastel
import SpotifyLogin
import UIKit

class ViewController: UIViewController {
    private var appleMusic: MusicSearcher!
    private var spotify: MusicSearcher!

    private var link: String?

    // Mark: Properties

    @IBOutlet var convertButton: UIButton!
    @IBOutlet var titleLabel: UILabel!

    var pastelView: PastelView!

    // Mark: Functions

    func initApp(link: String) {
        self.link = link
        spotify = SpotifySearcher { _, error in
            if error == nil {
                // Start the search using the new Apple Music object
                self.appleMusic = AppleMusicSearcher()
                self.handleLink(link: self.link ?? "")
            } else {
                // Display an error for logging in
                self.updateAppearance(title: "Error getting Spotify credentials", color: UIColor.red, enabled: false)
            }
        }
    }

    override func viewDidLoad() {
        pastelView = PastelView(frame: view.bounds)
    }

    /// Animates the color conversion in the app
    ///
    /// - Parameters:
    ///   - title: Name to set the label to
    ///   - color: Color to set the background to
    ///   - enabled: Whether or not the convert button should be shown
    private func updateAppearance(title: String, color: UIColor, enabled: Bool) {
        convertButton.setTitle(title, for: .normal)
        // Animate color shift
        UIView.animate(withDuration: 3.0, delay: 0.0, options: [.allowUserInteraction], animations: {
            self.titleLabel.textColor = UIColor.white
            self.view.backgroundColor = color
            self.convertButton.setTitleColor(UIColor.white, for: .normal)
        })

        convertButton.isEnabled = enabled
    }

    /// "Connects" Apple Music and Spotify for searching between them. Finds matching
    /// data from opposite source and allows the user to open links in opposite app.
    ///
    /// - Parameter link: Link to handle
    private func handleLink(link: String) {
        // Resets the label text while converting
        titleLabel.text = "Convertify"

        // Decides what to do with the link
        switch true {
        // Converts playlists
        case link.contains("/playlist/"): handlePlaylist(link: link)

        // Ignores radio stations
        case link.contains("/station/"):
            updateAppearance(title: "I cannot convert radio stations ☹️", color: UIColor.red, enabled: false)

        // Extracts Spotify data and searches for Apple Music links when it includes a Spotify link
        case link.contains(SearcherURL.spotify):
            handleSearching(link: link, source: spotify, destination: appleMusic)

        // Extracts Apple Music data and searches for Spotify links when it includes an Apple Music link
        case link.contains(SearcherURL.appleMusic):
            handleSearching(link: link, source: appleMusic, destination: spotify)

        // Lets the user know I don't know how to handle whatever is in their clipboard
        default:
            updateAppearance(title: "No Spotify or Apple Music link found in clipboard", color: UIColor.gray, enabled: false)
        }
    }

    /// Handles searching between the source and destination
    ///
    /// - Parameters:
    ///   - link: link to search with
    ///   - source: Source service of the link
    ///   - destination: Destination to open the search result in
    private func handleSearching(link: String, source: MusicSearcher, destination: MusicSearcher) {
        // Search the source
        source.search(link: link) { type, name, artist, error in
            print("Searching \(source.serviceName) \(error == nil ? "successful" : "failed")")

            if error == nil {
                self.titleLabel.text = (artist == nil ? name! : name! + " by " + artist!)

                destination.search(name: name! + " " + (artist ?? ""), type: type!) { link, error in
                    print("Searching \(destination.serviceName) \(error == nil ? "successful" : "failed")")
                    // Update some of the visible parts of the app to show it is NOT loading
                    if error == nil {
                        self.link = link
                        self.updateAppearance(title: "Open in \(destination.serviceName)", color: destination.serviceColor, enabled: true)
                    } else {
                        self.updateAppearance(title: "Error getting \(destination.serviceName) data", color: UIColor.red, enabled: false)
                    }
                }
            } else {
                // Display the error
                self.titleLabel.text = "Error getting \(source.serviceName) data"
                self.updateAppearance(title: "Link might be formatted incorrectly", color: UIColor.red, enabled: false)
            }
        }
    }

    /// Decides how to convert and process playlist
    ///
    /// - Parameter link: link to playlist
    private func handlePlaylist(link: String) {
        // Ensure user is logged in
        handleSpotifyLogin { token, error in
            if error == nil {
                let spotifyPlaylistSearcher = SpotifyPlaylistSearcher(token: token)
                let appleMusicPlaylistSearcher = AppleMusicPlaylistSearcher()

                if link.contains("open.spotify.com") {
                    self.convertPlaylist(link: link, source: spotifyPlaylistSearcher, destination: appleMusicPlaylistSearcher)
                } else if link.contains("itunes.apple.com") {
                    self.convertPlaylist(link: link, source: appleMusicPlaylistSearcher, destination: spotifyPlaylistSearcher)
                } else {
                    self.updateAppearance(title: "I don't recognize where that playlist is from ☹️", color: UIColor.red, enabled: false)
                }
            } else {
                self.updateAppearance(title: "We had trouble logging into Spotify ☹️", color: UIColor.red, enabled: false)
            }
        }
    }

    /// Ensures that the user is logged into Spotify and the application has permission to modify
    /// private playlists
    ///
    /// - Parameter completion: What to do with login token after login is completed
    private func handleSpotifyLogin(completion: @escaping (String?, Error?) -> Void) {
        SpotifyLogin.shared.getAccessToken { token, error in
            switch error {
            case nil: completion(token, error)
            default: SpotifyLoginPresenter.login(from: self, scopes: [.playlistModifyPrivate])
            }
        }
    }

    /// Adds the playlist
    ///
    /// - Parameters:
    ///   - destination: where to add the playlist
    ///   - trackList: list of tracks [track name: artist name]
    ///   - playlistName: Name of the playlist
    private func addPlaylist(destination: PlaylistSearcher, trackList: [String: String], playlistName: String) {
        // Show some cool animations
        addPastelView()
        titleLabel.text = playlistName
        updateAppearance(title: "Converting now, this might take a while", color: UIColor.darkGray, enabled: false)
        destination.addPlaylist(trackList: trackList, playlistName: playlistName) { _, _, error in
            if error == nil {
                self.updateAppearance(title: "Converted successfully", color: UIColor.darkGray, enabled: false)
            } else {
                self.updateAppearance(title: "We had problems converting this playlist", color: UIColor.red, enabled: false)
            }
            self.pastelView.removeFromSuperview()
        }
    }

    /// Converts a playlist
    ///
    /// - Parameters:
    ///   - link: link of playlist
    ///   - source: source for the playlist
    ///   - destination: where to add the playlist
    private func convertPlaylist(link: String, source: PlaylistSearcher, destination: PlaylistSearcher) {
        source.getTrackList(link: link) { trackList, playlistName, error in
            if error == nil {
                let alert = UIAlertController(title: "Add \(playlistName ?? "") to Spotify?",
                                              message: "This playlist will be added to your Spotify library with the closest matches we can find.",
                                              preferredStyle: UIAlertController.Style.alert)

                // Yes, add the playlist
                alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) { _ in
                    self.addPlaylist(destination: destination,
                                     trackList: trackList ?? [:],
                                     playlistName: playlistName ?? "New Playlist")
                })

                // TODO: Add a no action to the action thing

                // Show the alert
                self.present(alert, animated: true, completion: nil)
            } else {
                self.updateAppearance(title: "We had problems converting this playlist", color: UIColor.red, enabled: false)
            }
        }
    }

    /// Adds pretty animation for converting playlists
    private func addPastelView() {
        // Custom Direction
        pastelView.startPastelPoint = .left
        pastelView.endPastelPoint = .right
        // Custom Duration
        pastelView.animationDuration = 3.0
        // Custom Color
        pastelView.setColors([spotify.serviceColor, appleMusic.serviceColor])
        pastelView.alpha = 0.0
        UIView.animate(withDuration: 3.0, delay: 0.0, options: [.allowUserInteraction], animations: {
            self.pastelView.startAnimation()
            self.view.insertSubview(self.pastelView, at: 0)
            self.pastelView.alpha = 1.0
        })
    }

    // Mark: Actions

    /// Opens the link in the opposite app
    @IBAction func openSong(_: Any) {
        if link != nil {
            UIApplication.shared.open(URL(string: link!)!, options: [:])
        }
    }
}
